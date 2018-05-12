require "io"
require "readline"

require "./reader"
require "./printer"

require "./types"

require "./env"

STDIN.blocking = true

module Step3
  extend self

  class Step
    @repl_env = Env::Env.new

    def initialize
      @repl_env.set(
        Mal::Symbol.new("+"), ->(args : Array(Mal::Type)) { (args[0].as(Int64) + args[1].as(Int64)).as(Mal::Type) }
      )
      @repl_env.set(
        Mal::Symbol.new("-"), ->(args : Array(Mal::Type)) { (args[0].as(Int64) - args[1].as(Int64)).as(Mal::Type) }
      )
      @repl_env.set(
        Mal::Symbol.new("*"), ->(args : Array(Mal::Type)) { (args[0].as(Int64) * args[1].as(Int64)).as(Mal::Type) }
      )
      @repl_env.set(
        Mal::Symbol.new("/"), ->(args : Array(Mal::Type)) { (args[0].as(Int64) / args[1].as(Int64)).to_i64.as(Mal::Type) }
      )
    end

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

    def eval_ast(ast, env)
      case ast
      when Mal::Symbol
        return env.get(ast)
      when Hash
        ast.each_key { |k| ast[k] = eval(ast[k], env) }
        return ast
      when Array
        ast.map! { |e| eval(e, env) }
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

    DEF_SYM = Mal::Symbol.new("def!")
    LET_SYM = Mal::Symbol.new("let*")

    def eval(ast, env)
      case ast
      when Array
        if ast.empty?
          return ast
        else
          case ast[0]
          when DEF_SYM
            env.set(ast[1].as(Mal::Symbol), eval(ast[2], env))
          when LET_SYM
            let_env = Env::Env.new(env)
            let_arg = ast[1]
            case let_arg
            when Array
              let_arg.each_index do |i|
                if i % 2 == 0
                  let_env.set(let_arg[i].as(Mal::Symbol), eval(let_arg[i + 1], let_env))
                end
              end
            end

            return eval(ast[2], let_env)
          else
            return func_call(eval_ast(ast, env))
          end
        end
      else
        return eval_ast(ast, env)
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
          ), @repl_env
        )
      )
    end
  end
end

step = Step3::Step.new

while true
  begin
    puts step.rep
  rescue Reader::CommentEx
    # do nothing
  rescue err
    puts err.message
  end
end
