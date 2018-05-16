module Mal
  class Symbol
    @str : String

    def initialize(@str)
    end

    def to_s(io : IO)
      io << @str
    end

    def_equals_and_hash @str
    def_clone
  end

  class Keyword
    @str : String

    def initialize(@str)
    end

    def to_s(io : IO)
      io << @str
    end

    def_equals_and_hash @str
    def_clone
  end

  class Vector(T) < Array(T)
  end

  class Map(MapKey, T) < Hash(MapKey, T)
  end

  class MalFunc
    getter ast : Mal::Type
    getter params : Mal::Type
    getter env : Env::Env
    getter fn : Proc(Array(Mal::Type), Mal::Type)

    def initialize(@ast, @params, @env, @fn)
    end
  end

  alias MapKey = Mal::Keyword | String

  alias Type = Mal::Symbol |
               Mal::Keyword |
               Int64 |
               Vector(Type) |
               Array(Type) |
               Map(MapKey, Type) |
               Bool |
               Nil |
               String |
               Proc(Array(Mal::Type), Mal::Type) |
               MalFunc
end
