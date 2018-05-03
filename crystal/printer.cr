require "./types"

module Printer
  extend self

  def print_each(str, mal : Mal::Type)
    mal.each_index do | i |
      if i > 0
        str << ' '
      end
      str << pr_str(mal[i])
    end
  end

  def pr_str(mal : Mal::Type, print_readably = true)
    case mal
    when Nil
      return "nil"
    when Bool | Int64 | Mal::Symbol | Mal::Keyword
      return mal.to_s
    when String
      if print_readably
        readable = mal
        .gsub("\\", "\\\\")
        .gsub("\"", "\\\"")
        .gsub("\n", "\\n")
        
        return "\"#{readable}\""
      else
        return "\"#{mal}\""
      end
    when Mal::Vector(Mal::Type)
      str = String.build do |str|
        str << '['
        print_each(str, mal)
        str << ']'
      end
      return str
    when Mal::Map(Mal::MapKey, Mal::Type)
      str = String.build do |str|
        str << '{'
        first = true
        mal.each_key do | k |
          if !first
            str << ' '
            first = false
          end
          str << pr_str(k) << ' ' << pr_str(mal[k])
        end
        str << '}'
      end
      return str
    when Array(Mal::Type)
      str = String.build do |str|
        str << '('
        print_each(str, mal)
        str << ')'
      end
      return str
    end      
  end
end
