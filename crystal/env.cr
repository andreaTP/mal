require "./types"

module Env
  class Env
    @outer : (Env | Nil) = nil
    @data = Hash(Mal::Symbol, Mal::Type).new

    def initialize(@outer = nil)
    end

    def set(sym, value)
      @data[sym] = value
    end

    def find(sym)
      elem = @data[sym]?
      outer = @outer

      if elem.nil?
        if outer.nil?
          return nil
        else
          return outer.find(sym)
        end
      else
        return self
      end
    end

    def get(sym)
      env = find(sym)
      if env.nil?
        raise "Not found"
      else
        return env.@data[sym]
      end
    end
  end
end
