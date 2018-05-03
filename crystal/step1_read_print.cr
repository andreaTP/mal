require "io"
require "readline"

require "./reader"
require "./printer"

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

  def eval(*args)
    return args[0]
  end

  def print(*args)
    return Printer.pr_str(args[0], print_readably: true)
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
