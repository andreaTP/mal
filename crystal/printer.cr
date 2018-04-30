require "./types"

module Printer
  extend self

  def pr_str(mal : Mal::Type, print_readably = true)
    case mal
    when Nil
      return "nil"
    when Bool | Int64 | Mal::Symbol
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
    when Array(Mal::Type)
      str = String.build do |str|
        str << '('
        mal.each_index do | i |
          if i > 0
            str << ' '
          end
          str << pr_str(mal[i])
        end
        str << ')'
      end
      return str
    end      
  end
end
