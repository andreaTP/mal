require "io"
require "readline"

require "./reader"
require "./printer"
require "./types"
require "./env"
require "./core"

STDIN.blocking = true

module Step9
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

    def is_pair(arg)
      case arg
      when Array
        !arg.empty?
      else
        false
      end
    end

    DEF_SYM = Mal::Symbol.new("def!")
    LET_SYM = Mal::Symbol.new("let*")

    DO_SYM = Mal::Symbol.new("do")
    IF_SYM = Mal::Symbol.new("if")

    FN_SYM = Mal::Symbol.new("fn*")

    EVAL_SYM = Mal::Symbol.new("eval")

    QUOTE_SYM         = Mal::Symbol.new("quote")
    QUASIQUOTE_SYM    = Mal::Symbol.new("quasiquote")
    UNQUOTE_SYM       = Mal::Symbol.new("unquote")
    SPLICEUNQUOTE_SYM = Mal::Symbol.new("splice-unquote")

    DEFMACRO_SYM    = Mal::Symbol.new("defmacro!")
    MACROEXPAND_SYM = Mal::Symbol.new("macroexpand")

    TRY_SYM   = Mal::Symbol.new("try*")
    CATCH_SYM = Mal::Symbol.new("catch*")

    def quasiquote(ast)
      res = [] of Mal::Type
      if !is_pair(ast)
        res << QUOTE_SYM
        res << ast
        return res
      else
        arr = ast.as(Array)

        if arr[0] == UNQUOTE_SYM
          return arr[1]
        elsif (is_pair(arr[0]) &&
              arr[0].is_a?(Array) &&
              arr[0].as(Array)[0] == SPLICEUNQUOTE_SYM)
          res << Mal::Symbol.new("concat")
          res << arr[0].as(Array)[1]
          res << quasiquote(arr.skip(1).as(Mal::Type))
          return res
        else
          res << Mal::Symbol.new("cons")
          res << quasiquote(arr[0])
          res << quasiquote(arr.skip(1).as(Mal::Type))
          return res
        end
      end
    end

    def is_macro_call(ast, env)
      case ast
      when Array
        begin
          env.get(ast.as(Array)[0].as(Mal::Symbol)).as(Mal::MalFunc).is_macro
        rescue
          false
        end
      else
        false
      end
    end

    def macroexpand(ast, env)
      while (is_macro_call(ast, env))
        fn = env.get(ast.as(Array)[0].as(Mal::Symbol)).as(Mal::MalFunc)
        begin
          ast = fn.fn.call(ast.as(Array).skip(1))
        rescue
          return nil.as(Mal::Type)
        end
      end
      return ast
    end

    def eval(ast : Mal::Type, env)
      # puts("ast is #{ast}")
      while true
        case ast
        when Array
          ast = macroexpand(ast, env)
          if !ast.is_a?(Array)
            return eval_ast(ast, env)
          else
            ast = ast.as(Array)
          end
          if ast.empty?
            return ast
          else
            case ast[0]
            when TRY_SYM
              begin
                return eval(ast[1], env)
              rescue ex : Mal::MalException
                err_env = Env::Env.new(env)
                err_env.set(ast[2].as(Array)[1].as(Mal::Symbol), ex.err)
                return eval(ast[2].as(Array)[2], err_env)
              end
            when MACROEXPAND_SYM
              return macroexpand(ast[1], env)
            when DEFMACRO_SYM
              ast1 = ast[1].as(Mal::Symbol)
              ast2 = ast[2]
              fn = eval(ast2, env)
              case fn
              when Mal::MalFunc
                fn.is_macro = true
                return env.set(ast1, fn)
              end
            when QUOTE_SYM
              return ast[1]
            when QUASIQUOTE_SYM
              ast = quasiquote(ast[1])
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

step = Step9::Step.new
# define not
step.rep("(def! not (fn* (a) (if a false true)))")
# define load-file
step.rep(%{(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) ")")))))})

# define cond macro
step.rep(%{(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw "odd number of forms to cond")) (cons 'cond (rest (rest xs)))))))})
# define or macro
step.@repl_env.set(Mal::Symbol.new("or_FIXME"), "yes".as(Mal::Type))
step.rep(%{(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) `(let* (or_FIXME ~(first xs)) (if or_FIXME or_FIXME (or ~@(rest xs))))))))})

vec = [] of Mal::Type
ARGV.skip(1).each { |e| vec << e.as(Mal::Type) }
step.@repl_env.set(Mal::Symbol.new("*ARGV*"), vec)

if ARGV[0]?
  step.rep(%{(load-file "#{ARGV[0]}")})
  exit 0
else
  while true
    begin
      prompt = "user> "
      instr = Readline.readline(prompt, true)

      if instr.nil?
        exit 0
      else
        begin
          puts step.rep(instr)
        rescue Reader::CommentEx
          # do nothing
        end
      end
    rescue err
      puts err.message
    end
  end
end
