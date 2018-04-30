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

  def read_str(str)
    reader = Reader.new(tokenizer(str))

    read_form(reader)
  end

  MAL_REGEX = /[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)/

  def tokenizer(str) : Array(String)

    match = MAL_REGEX.match(str).not_nil!
    arr = match.captures.compact

    while !match.post_match.empty?
      match = MAL_REGEX.match(match.post_match).not_nil!

      arr.concat(match.captures.compact)
    end

    return arr
  end

  def read_form(reader) : Mal::Type
    case reader.peek
    when "("
      return read_list(reader)
    else
      return read_atom(reader)
    end
  end

  def if_s(str, &block)
    match = /["](.*)["]/.match(str)

    if !match.nil? && !match.captures.compact.empty?
      return yield match
    else
      return nil
    end
  end

  def get_s(str)
    if_s(str) { | match | match.captures.compact[0] }
  end

  def is_s(str)
    if_s(str) { | _ | str }
  end

  def if_comment(str)
    match = /[;].*/.match(str)

    if !match.nil?
      return str
    else
      return nil
    end
  end

  class CommentEx < Exception end

  def read_atom(reader) : Mal::Type
    case reader.peek
    when if_comment(reader.peek)
      raise CommentEx.new
    when "true"
      return true
    when "false"
      return false
    when "nil"
      return nil
    when is_s(reader.peek)
      return get_s(reader.peek).not_nil!
        .gsub("\\\"", "\"")
        .gsub("\\n", "\n")
        .gsub("\\\\", "\\")
        
    when .to_i64?
      return reader.peek.to_i64
    when "(", ")"
      raise "Parenthesis not matched"
    when .to_s
      return Mal::Symbol.new(reader.peek.to_s)
    else
      raise "Error parsing atom #{reader.peek}"
    end
  end

  def read_list(reader)
    list = [] of Mal::Type

    begin
      while reader.next != ")"
        list << read_form(reader)
      end

      return list
    rescue err
      raise "Error matching list (#{err.message})"
    end
  end
end
