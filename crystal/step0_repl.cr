require "io"
require "readline"

module Step0
  extend self

  STDIN.blocking = true
 
  def loopme()
    instr = Readline.readline("user> ", true)

    if instr.nil?
      exit 0
    else
      return instr
    end
  end

  def read(*args)
    return args[0]
  end

  def eval(*args)
    return args[0]
  end

  def print(*args)
    return args[0]
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
  puts Step0.rep()
end
