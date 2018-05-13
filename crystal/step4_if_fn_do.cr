require "io"
require "readline"

require "./reader"
require "./printer"
require "./types"
require "./env"
require "./core"

STDIN.blocking = true

module Step4
  extend self

  class Step
    @repl_env = Env::Env.new

    def initialize
      Core::NS.each do |k, v|
        @repl_env.set(k, v)
      end
    end

    def read(*args)
      return Reader.read_str(args[0])
    end

    def eval_ast(ast, env)
      case ast
      when Mal::Symbol
        res = env.get(ast)
        return res
      when Hash
        evaluated = ast # just to make the compiler happy...
        keys = ast.keys
        vals = ast.values
        keys.each_index { |i| evaluated[keys[i]] = eval(vals[i], env) }

        return evaluated
      when Array
        evaluated = [] of Mal::Type
        ast.each { |e| evaluated << eval(e, env) }
        return evaluated
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

    DO_SYM = Mal::Symbol.new("do")
    IF_SYM = Mal::Symbol.new("if")

    FN_SYM = Mal::Symbol.new("fn*")

    def eval(ast : Mal::Type, env)
      case ast
      when Array
        if ast.empty?
          return ast
        else
          case ast[0]
          when DO_SYM
            return eval_ast(ast.skip(1), env).last
          when IF_SYM
            if eval(ast[1], env)
              return eval(ast[2], env)
            else
              if ast[3]?
                return eval(ast[3], env)
              else
                return nil
              end
            end
          when FN_SYM
            binds = [] of (Mal::Symbol)
            ast[1].as(Array).each do |b|
              case b
              when Mal::Symbol
                binds << b
              end
            end
            ast2 = ast[2]

            return ->(args : Array(Mal::Type)) {
              eval(ast2, Env::Env.new(env, binds, args)).as(Mal::Type)
            }
          when DEF_SYM
            ast1 = ast[1].as(Mal::Symbol)
            ast2 = ast[2]
            env.set(ast1, eval(ast2, env))
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
            el = eval_ast(ast, env)
            return func_call(el)
          end
        end
      else
        return eval_ast(ast, env)
      end
    end

    def print(*args)
      return Printer.pr_str(args[0], print_readably: true)
    end

    def rep(str)
      return print(
        eval(
          read(
            str
          ), @repl_env
        )
      )
    end
  end
end

step = Step4::Step.new
# define not
step.rep("(def! not (fn* (a) (if a false true)))")

while true
  begin
    instr = Readline.readline("user> ", true)

    if instr.nil?
      exit 0
    else
      puts step.rep(instr)
    end
  rescue Reader::CommentEx
    # do nothing
  rescue err
    puts err.message
  end
end
