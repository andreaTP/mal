
module Mal

  class Symbol
    @str : String
    def initialize(@str)
    end
    def to_s(io : IO)
      io << @str
    end
  end

  alias Type =  Mal::Symbol |
                Int64 |
                Array(Type) |
                Bool |
                Nil |
                String
  
  # Nil |
  #              Bool |
  #              Int64 |
  #              Float64 |
  #              String |
  #              Array(Type) |
  #              Hash(String, Type)
end