require "./types"

module Reader
  extend self

  class Reader
    @tokens = [] of String
    @position = 0

    def initialize(tokens)
      @tokens = tokens
    end

    def next
      @position += 1
      return @tokens[@position]
    end

    def peek
      return @tokens[@position]
    end
  end

  def read_str(str) : Mal::Type
    reader = Reader.new(tokenizer(str))

    read_form(reader, nil)
  end

  MAL_REGEX = /[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)/

  def tokenizer(str) : Array(String)
    arr = [] of String
    remaining = str

    loop do
      match = MAL_REGEX.match(remaining).not_nil!
      arr.concat(match.captures.compact)

      break if match.post_match.empty? || remaining == match.post_match

      remaining = match.post_match
    end

    return arr
  end

  def read_form(reader, end_char) : Mal::Type
    case reader.peek
    when "("
      return read_list(reader, end_char: ")")
    when "["
      vec = Mal::Vector(Mal::Type).new
      read_list(reader, end_char: "]").each do |e|
        vec << e
      end
      return vec
    when "{"
      map = Mal::Map(Mal::MapKey, Mal::Type).new
      elems = read_list(reader, end_char: "}")
      elems.each_index do |i|
        if i % 2 == 0
          key = elems[i]
          case key
          when Mal::MapKey
            map[key] = elems[i + 1]
          else
            raise "error in matching"
          end
        end
      end
      return map
    else
      return read_atom(reader)
    end
  end

  def if_match(str, re, &block)
    match = re.match(str)

    if !match.nil? && !match.captures.compact.empty?
      return yield match
    else
      return nil
    end
  end

  def get_s(str)
    if_match(str, /["](.*)["]/) { |match| match.captures.compact[0] }
  end

  def is_s(str)
    if_match(str, /["](.*)["]/) { |_| str }
  end

  def if_cond(str, &block)
    if yield
      return str
    else
      return nil
    end
  end

  class CommentEx < Exception
  end

  def read_macro(name, reader)
    list = [] of Mal::Type
    list << Mal::Symbol.new(name)
    reader.next
    list << read_form(reader, nil)
    return list
  end

  def read_atom(reader) : Mal::Type
    case reader.peek
    when if_cond(reader.peek) { reader.peek.starts_with?(';') }
      raise CommentEx.new
    when "true"
      return true
    when "false"
      return false
    when "nil"
      return nil
    when if_cond(reader.peek) { reader.peek.starts_with?(':') }
      return Mal::Keyword.new(reader.peek.to_s)
    when if_cond(reader.peek) { reader.peek.starts_with?('\'') }
      return read_macro("quote", reader)
    when if_cond(reader.peek) { reader.peek.starts_with?('`') }
      return read_macro("quasiquote", reader)
    when if_cond(reader.peek) { reader.peek.starts_with?("~@") }
      return read_macro("splice-unquote", reader)
    when if_cond(reader.peek) { reader.peek.starts_with?('~') }
      return read_macro("unquote", reader)
    when is_s(reader.peek)
      str = String.build do |str|
        slash = false
        get_s(reader.peek).not_nil!.each_char do |c|
          if !slash && c == '\\'
            slash = true
          elsif slash
            if c == 'n'
              str << '\n'
            elsif c == '"'
              str << '"'
            elsif c == '\\'
              str << '\\'
            end
            slash = false
          else
            str << c
          end
        end
      end
      return str
    when .to_i64?
      return reader.peek.to_i64
    when .to_s
      return Mal::Symbol.new(reader.peek.to_s)
    else
      raise "Error parsing atom #{reader.peek}"
    end
  end

  def read_list(reader, end_char)
    list = [] of Mal::Type

    begin
      while reader.next != end_char
        list << read_form(reader, end_char)
      end

      return list
    rescue err
      raise "Error matching list (#{err.message})"
    end
  end
end
