
module Mal

  class Symbol
    @str : String
    def initialize(@str)
    end
    def to_s(io : IO)
      io << @str
    end
  end

  class Keyword
    @str : String
    def initialize(@str)
    end
    def to_s(io : IO)
      io << @str
    end
  end

  class Vector(T) < Array(T)
  end
  class Map(MapKey, T) < Hash(MapKey, T)
  end

  alias MapKey = Mal::Keyword | String

  alias Type =  Mal::Symbol |
                Mal::Keyword |
                Int64 |
                Vector(Type) |
                Array(Type) |
                Map(MapKey, Type) |
                Bool |
                Nil |
                String
  
end