# Example: read two characters

# Haskell do notation:
#   do
#     c1 <- getc;
#     c2 <- getc;
#     return (c1,c2)
# Equivalent to:
#   getc >>= \c1 -> getc >>= \c2 return (c1, c2)

class M
  def initialize(v)
    @v = v
  end

  def bind(&f)
    f[@v]
  end

  def value
    @v
  end
end

def getc
  M.new(STDIN.getc)
end

puts 'type a couple of characters...'

result = getc.bind { |c1| getc.bind { |c2| M.new([c1,c2]) } }

# puts "Result: #{result.value.inspect}"
result.bind { |value| puts "Result: #{value.inspect}" }

STDIN.gets

# Example: read one character, output twice

# In Haskell:
#   do
#     c <- getChar
#     putChar c;
#     putChar c;
#
#   getChar >>= \c -> (putChar c >> putChar c))
#
#   getChar >>= \c -> (putChar c >>= \_ -> putChar c))

def putc(c)
  STDOUT << c
  M.new(nil)
end

puts 'type a character...'

result = getc.bind { |c| putc(c).bind { putc(c) }  }

puts "\nResult: #{result.value.inspect}"
