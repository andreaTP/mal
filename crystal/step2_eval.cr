require "io"
require "readline"

require "./reader"
require "./printer"

require "./types"

STDIN.blocking = true

module Step1
  extend self
 
  def loopme()
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

  alias MalApply = Mal::Type | Proc(Array(MalApply), Mal::Type) | Array(MalApply)

  REPL_ENV = {
    "+" => ->(args : Array(MalApply)) { (args[0].as(Int64) + args[1].as(Int64)).as(Mal::Type) },
    "-" => ->(args : Array(MalApply)) { (args[0].as(Int64) - args[1].as(Int64)).as(Mal::Type) },
    "*" => ->(args : Array(MalApply)) { (args[0].as(Int64) * args[1].as(Int64)).as(Mal::Type) },
    "/" => ->(args : Array(MalApply)) { (args[0].as(Int64) / args[1].as(Int64)).to_i64.as(Mal::Type) },
  }

  def eval_ast(ast, env : Hash(String, Proc(Array(MalApply), Mal::Type))) : MalApply
    case ast
    when Mal::Symbol
      return env[ast.to_s]
    when Array
      return ast.map { | e | eval(e).as(MalApply) }
    else
      return ast
    end
  end

  def func_call(elems : MalApply)
    func = elems.first
    case func
    when Proc(Array(MalApply), Mal::Type)
      return func.call(elems.skip(1))
    else
      raise "no operation in head position"
    end
  end

  def eval(ast) : MalApply
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
    return Printer.pr_str(args[0].as(Mal::Type), print_readably: true)
  end

  def rep()
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
    puts Step1.rep()
  rescue Reader::CommentEx
    # do nothing
  rescue err
    puts err.message
  end
end
