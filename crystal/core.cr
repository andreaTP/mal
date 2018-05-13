require "./types"
require "./printer"

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

module Core
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
      str = String.build do |str|
        first = true
        args.each do |a|
          if !first
            str << ' '
          end
          first = false
          str << Printer.pr_str(a, print_readably: true)
        end
      end
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
      # same as sp-str to be rafactored
      str = String.build do |str|
        first = true
        args.each do |a|
          if !first
            str << ' '
          end
          first = false
          str << Printer.pr_str(a, print_readably: true)
        end
      end
      puts str
      nil.as_mal
    },
    mal_symbol("println") => ->(args : Args) {
      # same as sp-str to be rafactored
      str = String.build do |str|
        first = true
        args.each do |a|
          if !first
            str << ' '
          end
          first = false
          str << Printer.pr_str(a, print_readably: false)
        end
      end
      puts str
      nil.as_mal
    },
  }
end
