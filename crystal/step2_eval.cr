require "io"
require "readline"

require "./reader"
require "./printer"

require "./types"

STDIN.blocking = true

module Step2
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

  def eval_ast(ast, env)
    case ast
    when Mal::Symbol
      return env[ast.to_s]
    when Hash
      ast.each_key { |k| ast[k] = eval(ast[k]) }
      return ast
    when Array
      ast.map! { |e| eval(e) }
      return ast
    when Mal::Type
      return ast
    else
      raise "unrecognised ast node"
    end
  end

  def func_call(elems)
    func = elems.first
    case func
    when Proc(Array(Mal::Type), Mal::Type)
      return func.call(elems.skip(1))
    else
      return elems
    end
  end

  def eval(ast)
    case ast
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
    puts Step2.rep
  rescue Reader::CommentEx
    # do nothing
  rescue err
    puts err.message
  end
end
