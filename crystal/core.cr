require "file"
require "readline"

require "./types"
require "./printer"
require "./reader"

module AsMal
  def as_mal
    self.as(Mal::Type)
  end

  def mal_symbol(str)
    Mal::Symbol.new(str)
  end
end

class Object
  include AsMal
end

module PrintHelper
  def print_str(args, separator, readable)
    str = String.build do |str|
      first = true
      args.each do |a|
        if !first
          str << separator
        end
        first = false
        str << Printer.pr_str(a, print_readably: readable)
      end
    end
    return str
  end
end

module Meta
  extend self
  META = Hash(Mal::Type, Mal::Type).new
end

module Core
  extend PrintHelper
  extend Meta
  alias Args = Array(Mal::Type)

  META = Hash(Mal::Type, Mal::Type).new

  NS = {
    mal_symbol("+") => ->(args : Args) {
      (args[0].as(Int64) + args[1].as(Int64)).as_mal
    },
    mal_symbol("-") => ->(args : Args) {
      (args[0].as(Int64) - args[1].as(Int64)).as_mal
    },
    mal_symbol("*") => ->(args : Args) {
      (args[0].as(Int64) * args[1].as(Int64)).as_mal
    },
    mal_symbol("/") => ->(args : Args) {
      (args[0].as(Int64) / args[1].as(Int64)).to_i64.as_mal
    },
    mal_symbol("list") => ->(args : Args) {
      args.as_mal
    },
    mal_symbol("list?") => ->(args : Args) {
      (args[0].is_a?(Array) && !args[0].is_a?(Mal::Vector)).as_mal
    },
    mal_symbol("empty?") => ->(args : Args) {
      args0 = args[0]
      case args0
      when Array
        args0.empty?.as_mal
      else
        false.as_mal
      end
    },
    mal_symbol("count") => ->(args : Args) {
      args0 = args[0]
      case args0
      when Array
        args0.size.to_i64.as_mal
      else
        0.to_i64.as_mal
      end
    },
    mal_symbol("=") => ->(args : Args) {
      # crystal array equality already cover arrays
      (args[0] == args[1]).as_mal
    },
    mal_symbol("<") => ->(args : Args) {
      (args[0].as(Int64) < args[1].as(Int64)).as_mal
    },
    mal_symbol("<=") => ->(args : Args) {
      (args[0].as(Int64) <= args[1].as(Int64)).as_mal
    },
    mal_symbol(">") => ->(args : Args) {
      (args[0].as(Int64) > args[1].as(Int64)).as_mal
    },
    mal_symbol(">=") => ->(args : Args) {
      (args[0].as(Int64) >= args[1].as(Int64)).as_mal
    },
    mal_symbol("pr-str") => ->(args : Args) {
      str = print_str(args, ' ', true)
      str.as_mal
    },
    mal_symbol("str") => ->(args : Args) {
      str = String.build do |str|
        args.each do |a|
          str << Printer.pr_str(a, print_readably: false)
        end
      end
      str.as_mal
    },
    mal_symbol("prn") => ->(args : Args) {
      str = print_str(args, ' ', true)
      puts str
      nil.as_mal
    },
    mal_symbol("println") => ->(args : Args) {
      str = print_str(args, ' ', false)
      puts str
      nil.as_mal
    },
    mal_symbol("read-string") => ->(args : Args) {
      # not sure why .as_mal is not working...
      Reader.read_str(args[0].as(String)).as(Mal::Type)
    },
    mal_symbol("slurp") => ->(args : Args) {
      str = File.read(args[0].to_s)
      # not mentioned in the guide ...
      str = str.gsub(/[.]*([;].*)/, "")
      str.as_mal
    },
    mal_symbol("atom") => ->(args : Args) {
      Mal::Atom.new(args[0]).as_mal
    },
    mal_symbol("atom?") => ->(args : Args) {
      args[0].is_a?(Mal::Atom).as_mal
    },
    mal_symbol("deref") => ->(args : Args) {
      args[0].as(Mal::Atom).data.as(Mal::Type)
    },
    mal_symbol("reset!") => ->(args : Args) {
      atom = args[0].as(Mal::Atom)
      atom.data = args[1]
      atom.data.as(Mal::Type)
    },
    mal_symbol("swap!") => ->(args : Args) {
      atom = args[0].as(Mal::Atom)
      fn_args = [] of Mal::Type
      fn_args << atom.data
      fn_args.concat(args.skip(2))

      args1 = args[1]
      case args1
      when Mal::MalFunc
        atom.data = args1.fn.call(fn_args)
      when Proc(Array(Mal::Type), Mal::Type)
        atom.data = args1.call(fn_args)
      end
      atom.data.as(Mal::Type)
    },
    mal_symbol("cons") => ->(args : Args) {
      res = [] of Mal::Type
      res << args[0]
      res.concat(args[1].as(Array)).as(Mal::Type)
    },
    mal_symbol("concat") => ->(args : Args) {
      ret = [] of Mal::Type
      args.each { |e| ret.concat(e.as(Array)) }
      ret.as_mal
    },
    mal_symbol("nth") => ->(args : Args) {
      begin
        args.as(Array)[0].as(Array)[(args.as(Array)[1]).as(Int64)].as(Mal::Type)
      rescue
        raise "nth: index out of range"
        nil.as_mal
      end
    },
    mal_symbol("first") => ->(args : Args) {
      begin
        args.as(Array)[0].as(Array)[0].as(Mal::Type)
      rescue
        nil.as_mal
      end
    },
    mal_symbol("rest") => ->(args : Args) {
      begin
        args.as(Array)[0].as(Array).skip(1).as(Mal::Type)
      rescue
        ([] of (Mal::Type)).as(Mal::Type)
      end
    },
    mal_symbol("throw") => ->(args : Args) {
      raise Mal::MalException.new(args[0])
    },
    mal_symbol("apply") => ->(args : Args) {
      vec = [] of Mal::Type
      args[1..-2].each { |e| vec << e }
      last = args.last
      case last
      when Array
        last.each { |e| vec << e }
      end

      args0 = args[0]
      case args0
      when Mal::MalFunc
        args0.fn.call(vec).as(Mal::Type)
      when Proc(Array(Mal::Type), Mal::Type)
        args0.call(vec).as(Mal::Type)
      else
        nil.as_mal
      end
    },
    mal_symbol("map") => ->(args : Args) {
      res = [] of Mal::Type

      args0 = args[0]
      args1 = args[1]
      case args1
      when Array
        args1.each do |a|
          case args0
          when Mal::MalFunc
            res << args0.fn.call([a.as(Mal::Type)])
          when Proc(Array(Mal::Type), Mal::Type)
            res << args0.call([a.as(Mal::Type)])
          end
        end
      end

      res.as_mal
    },
    mal_symbol("nil?") => ->(args : Args) {
      args[0].nil?.as_mal
    },
    mal_symbol("true?") => ->(args : Args) {
      args0 = args[0]
      args0.is_a?(Bool) ? args0.as_mal : false.as_mal
      if args0.is_a?(Bool)
        args0.as_mal
      else
        false.as_mal
      end
    },
    mal_symbol("false?") => ->(args : Args) {
      args0 = args[0]
      args0.is_a?(Bool) ? (!args0).as_mal : false.as_mal
    },
    mal_symbol("symbol?") => ->(args : Args) {
      args0 = args[0]
      args0.is_a?(Mal::Symbol) ? true.as_mal : false.as_mal
    },
    mal_symbol("symbol") => ->(args : Args) {
      Mal::Symbol.new(args[0].as(String)).as_mal
    },
    mal_symbol("keyword") => ->(args : Args) {
      Mal::Keyword.new(":#{args[0].as(String)}").as_mal
    },
    mal_symbol("keyword?") => ->(args : Args) {
      args[0].is_a?(Mal::Keyword).as_mal
    },
    mal_symbol("vector") => ->(args : Args) {
      ret = Mal::Vector(Mal::Type).new
      args.each { |e| ret << e }
      ret.as_mal
    },
    mal_symbol("vector?") => ->(args : Args) {
      args[0].is_a?(Mal::Vector).as_mal
    },
    mal_symbol("hash-map") => ->(args : Args) {
      ret = Mal::Map(Mal::MapKey, Mal::Type).new
      args.each_index do |i|
        if i % 2 == 0
          ret[args[i].as(Mal::MapKey)] = args[i + 1]
        end
      end
      ret.as_mal
    },
    mal_symbol("map?") => ->(args : Args) {
      args[0].is_a?(Mal::Map).as_mal
    },
    mal_symbol("assoc") => ->(args : Args) {
      ret = Mal::Map(Mal::MapKey, Mal::Type).new
      args0 = args[0]
      case args0
      when Mal::Map
        ret.merge!(args0)
        args.skip(1).each_index do |i|
          argsi = args[i]
          if i % 2 != 0
            case argsi
            when String | Mal::Keyword
              ret[argsi.as(Mal::MapKey)] = args[i + 1].as_mal
            end
          end
        end
      end
      ret.as_mal
    },
    mal_symbol("dissoc") => ->(args : Args) {
      ret = Mal::Map(Mal::MapKey, Mal::Type).new
      args0 = args[0]
      case args0
      when Mal::Map
        ret.merge!(args0)
        ret.reject!(args.skip(1))
      end
      ret.as_mal
    },
    mal_symbol("get") => ->(args : Args) {
      args0 = args[0]
      case args0
      when Mal::Map(Mal::MapKey, Mal::Type)
        args0[args[1].as(Mal::MapKey)]?.as(Mal::Type)
      else
        nil.as_mal
      end
    },
    mal_symbol("contains?") => ->(args : Args) {
      args[0].as(Mal::Map).has_key?(args[1].as(Mal::MapKey)).as_mal
    },
    mal_symbol("keys") => ->(args : Args) {
      ret = [] of Mal::Type
      ret.concat(args[0].as(Mal::Map).keys)
      ret.as_mal
    },
    mal_symbol("vals") => ->(args : Args) {
      ret = [] of Mal::Type
      ret.concat(args[0].as(Mal::Map).values)
      ret.as_mal
    },
    mal_symbol("sequential?") => ->(args : Args) {
      args[0].is_a?(Array).as_mal
    },
    mal_symbol("readline") => ->(args : Args) {
      Readline.readline(args[0].to_s, true).as_mal
    },
    mal_symbol("meta") => ->(args : Args) {
      # have to verify the hashes ...
      META[args[0]]?.as(Mal::Type)
    },
    mal_symbol("with-meta") => ->(args : Args) {
      args0 = args[0]
      # TODO - improve me
      if args0.responds_to?(:clone)
        case args0
        when Mal::MalFunc
          ret = args0.clone
          META[ret] = args[1]
          ret.as(Mal::Type)
        when Mal::Vector
          ret = Mal::Vector(Mal::Type).new
          ret.concat(args0)
          META[ret] = args[1]
          ret.as(Mal::Type)
        when Array
          ret = [] of (Mal::Type)
          ret.concat(args0)
          META[ret] = args[1]
          ret.as(Mal::Type)
        when Mal::Map
          ret = Mal::Map(Mal::MapKey, Mal::Type).new
          ret.merge!(args0)
          META[ret] = args[1]
          ret.as(Mal::Type)
        else # verify this
          ret = args0
          META[ret] = args[1]
          ret.as(Mal::Type)
        end
      else
        raise "not clonable #{args[0]}"
        nil.as_mal
      end
    },
    mal_symbol("number?") => ->(args : Args) {
      args[0].is_a?(Int64).as_mal
    },
    mal_symbol("string?") => ->(args : Args) {
      args[0].is_a?(String).as_mal
    },
    mal_symbol("fn?") => ->(args : Args) {
      (args[0].is_a?(Proc) || (
        args[0].is_a?(Mal::MalFunc) && !args[0].as(Mal::MalFunc).is_macro
      )
        ).as_mal
    },
    mal_symbol("macro?") => ->(args : Args) {
      args0 = args[0]
      case args0
      when Mal::MalFunc
        args0.is_macro.as_mal
      else
        false.as_mal
      end
    },
    mal_symbol("time-ms") => ->(args : Args) {
      Time.utc_now.epoch_ms.as_mal
    },
    mal_symbol("conj") => ->(args : Args) {
      ret = nil
      args0 = args[0]
      case args0
      when Mal::Vector
        ret = Mal::Vector(Mal::Type).new
        ret.concat(args0).concat(args.skip(1))
      when Array
        ret = [] of Mal::Type
        ret.concat(args.skip(1).reverse).concat(args0)
      end
      ret.as_mal
    },
    mal_symbol("seq") => ->(args : Args) {
      ret = nil
      args0 = args[0]
      case args0
      when String
        if !args0.empty?
          ret = [] of Mal::Type
          args0.chars.each { |e| ret << e.to_s }
        end
      when Mal::Vector
        if !args0.empty?
          ret = [] of Mal::Type # Mal::Vector(Mal::Type).new
          args0.each { |e| ret << e }
        end
      when Array
        if !args0.empty?
          ret = [] of Mal::Type
          args0.each { |e| ret << e }
        end
      end
      ret.as_mal
    },
  }
end
