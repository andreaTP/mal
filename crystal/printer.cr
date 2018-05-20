require "./types"

module Printer
  extend self

  def print_each(str, mal : Mal::Type, print_readably)
    mal.each_index do |i|
      if i > 0
        str << ' '
      end
      str << pr_str(mal[i], print_readably)
    end
  end

  def pr_str(mal, print_readably = true)
    case mal
    when Nil
      return "nil"
    when Bool | Int64 | Mal::Symbol | Mal::Keyword
      return mal.to_s
    when String
      if print_readably
        str = String.build do |str|
          mal.each_char do |c|
            if c == '\n'
              str << %{\\n}
            elsif c == '"'
              str << %{\\\"}
            elsif c == '\\'
              str << %{\\\\}
            else
              str << c
            end
          end
        end

        return "\"#{str}\""
      else
        return "#{mal}"
      end
    when Proc(Array(Mal::Type), Mal::Type) | Mal::MalFunc
      return "#<function>"
    when Mal::Vector(Mal::Type)
      str = String.build do |str|
        str << '['
        print_each(str, mal, print_readably)
        str << ']'
      end
      return str
    when Mal::Map(Mal::MapKey, Mal::Type)
      str = String.build do |str|
        str << '{'
        first = true
        mal.each_key do |k|
          if !first
            str << ' '
          end
          first = false
          str << pr_str(k, print_readably) << ' ' << pr_str(mal[k], print_readably)
        end
        str << '}'
      end
      return str
    when Array(Mal::Type)
      str = String.build do |str|
        str << '('
        print_each(str, mal, print_readably)
        str << ')'
      end
      return str
    when Mal::Atom
      return "(atom #{mal.data})"
    when Exception
      return "\"#{mal.message}\""
    else
      raise "printer didn't matched the type"
    end
  end
end
