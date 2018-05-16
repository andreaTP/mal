require "io"
require "readline"

require "./reader"
require "./printer"
require "./types"
require "./env"
require "./core"

STDIN.blocking = true

module Step6
  extend self

  class Step
    @repl_env = Env::Env.new

    def initialize
      Core::NS.each do |k, v|
        @repl_env.set(k, v)
      end
      @repl_env.set(EVAL_SYM,
        ->(args : Array(Mal::Type)) {
          eval(args[0], @repl_env).as(Mal::Type)
        }.as(Proc(Array(Mal::Type), Mal::Type))
      )
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
        evaluated = ast # to make the compiler happy
        keys = ast.keys
        vals = ast.values
        keys.each_index { |i| evaluated[keys[i]] = eval(vals[i], env) }

        return evaluated
      when Array
        evaluated = Mal::Vector(Mal::Type).new
        ast.each { |e| evaluated << eval(e, env) }
        if ast.is_a?(Mal::Vector)
          return evaluated
        else
          return evaluated.as(Array)
        end
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

    EVAL_SYM = Mal::Symbol.new("eval")

    def eval(ast : Mal::Type, env)
      while true
        case ast
        when Array
          if ast.empty?
            return ast
          else
            case ast[0]
            when DO_SYM
              eval_ast(ast[1..-1], env)
              ast = ast.last
            when IF_SYM
              if eval(ast[1], env)
                ast = ast[2]
              else
                ast = ast[3]
              end
            when FN_SYM
              binds = [] of (Mal::Symbol)
              ast[1].as(Array).each do |b|
                case b
                when Mal::Symbol
                  binds << b
                end
              end
              ast1 = ast[1]
              ast2 = ast[2]

              fn = ->(args : Array(Mal::Type)) {
                eval(ast2, Env::Env.new(env, binds, args)).as(Mal::Type)
              }.as(Proc(Array(Mal::Type), Mal::Type))

              return Mal::MalFunc.new(ast2, ast1, env, fn)
            when DEF_SYM
              ast1 = ast[1].as(Mal::Symbol)
              ast2 = ast[2]
              return env.set(ast1, eval(ast2, env))
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

              env = let_env
              ast = ast[2]
            else
              el = eval_ast(ast, env)
              f = el[0]
              case f
              when Mal::MalFunc
                new_env = Env::Env.new(f.env, f.params, el.skip(1))
                ast = f.ast
                env = new_env
              else
                return func_call(el)
              end
            end
          end
        else
          return eval_ast(ast, env)
        end
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

step = Step6::Step.new
# define not
step.rep("(def! not (fn* (a) (if a false true)))")
# define load-file
step.rep(%{(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) ")")))))})

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
