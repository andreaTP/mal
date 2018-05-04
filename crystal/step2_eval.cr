require "io"
require "readline"

require "./reader"
require "./printer"

require "./types"

STDIN.blocking = true

module Step1
  extend self

  def loopme
    instr = Readline.readline("user> ", true)

    if instr.nil?
      exit 0
    else
      return instr
    end
  end

  def read(*args)
    return Reader.read_str(args[0])
  end

  REPL_ENV = {
    "+" => ->(args : Array(Mal::Type)) { (args[0].as(Int64) + args[1].as(Int64)).as(Mal::Type) },
    "-" => ->(args : Array(Mal::Type)) { (args[0].as(Int64) - args[1].as(Int64)).as(Mal::Type) },
    "*" => ->(args : Array(Mal::Type)) { (args[0].as(Int64) * args[1].as(Int64)).as(Mal::Type) },
    "/" => ->(args : Array(Mal::Type)) { (args[0].as(Int64) / args[1].as(Int64)).to_i64.as(Mal::Type) },
  }

  def eval_ast(ast, env : Hash(String, Proc(Array(Mal::Type), Mal::Type))) : Mal::Type
    case ast
    when Mal::Symbol
      return env[ast.to_s]
    when Hash
      ast.each_key { |k| ast[k]=eval(ast[k])}
      return ast
    when Array
      ast.map! { |e| eval(e).as(Mal::Type) }
      return ast # .map! { |e| eval(e).as(Mal::Type) }
    when Mal::Type
      return ast
    else
      raise "should not end up here"
    end
  end

  def func_call(elems : Mal::Type)
    func = elems.first
    case func
    when Proc(Array(Mal::Type), Mal::Type)
      return func.call(elems.skip(1))
    else
      raise "no operation in head position"
    end
  end

  def eval(ast) : Mal::Type
    case ast
    when Mal::Vector
      return eval_ast(ast, REPL_ENV)
    when Mal::Map
      return eval_ast(ast, REPL_ENV)
    when Array
      if ast.empty?
        return ast
      else
        return func_call(eval_ast(ast, REPL_ENV))
      end
    else
      return eval_ast(ast, REPL_ENV)
    end
  end

  def print(*args)
    return Printer.pr_str(args[0], print_readably: true)
  end

  def rep
    return print(
      eval(
        read(
          loopme
        )
      )
    )
  end
end

while true
  begin
    puts Step1.rep
  rescue Reader::CommentEx
    # do nothing
  rescue err
    puts err.message
  end
end
