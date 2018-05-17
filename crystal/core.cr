require "file"

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

module Core
  extend PrintHelper
  alias Args = Array(Mal::Type)

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
      File.read(args[0].to_s).as_mal
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
  }
end
