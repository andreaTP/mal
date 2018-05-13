require "./types"

module Env
  AT_SYM = Mal::Symbol.new("&")

  class Env
    @outer : (Env | Nil) = nil
    @data = Hash(Mal::Symbol, Mal::Type).new

    def initialize(@outer = nil, binds = Array(Mal::Symbol).new, exprs = Array(Mal::Type).new)
      binds.each_index do |i|
        if binds[i] == AT_SYM
          @data[binds[i + 1]] = exprs.skip(i)
          break
        else
          @data[binds[i]] = exprs[i]
        end
      end
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
        raise "Not found #{sym}"
      else
        return env.@data[sym]
      end
    end
  end
end
