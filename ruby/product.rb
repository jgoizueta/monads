# Test case: monadic cartesian product, as in Haskell:
# xs >>= \x -> ys >>= \y -> return (x,y)

# 1. Straight Ruby

xs = [1,2,3]
ys = [4,5]

r = xs.flat_map do |x|
  ys.map { |y| [x,y] }
end

# r = xs.flat_map { |x| ys.map { |y| [x,y] } }

puts r.inspect

# ------------------------------------------------
# 2. Turn Array into a monad

class Array
  def bind(&f)
    map(&f).inject(&:+)
  end
  def self.unit(v)
    [v]
  end
end


r = xs.bind { |x| ys.bind { |y| Array.unit([x,y]) } }

puts r.inspect

# ------------------------------------------------
# 3. Many monad

class Many
  def initialize(values)
    @values = values
  end
  attr_reader :values

  def bind(&f)
    Many.new(@values.map(&f).flat_map(&:values))
  end

  def self.unit(value)
    Many.new([value])
  end
end

r = Many.new(xs).bind { |x| Many.new(ys).bind { |y| Many.unit([x, y]) } }
puts r.values.inspect

# class Numeric
#   def product(values)
#     values.map{|v| [self, v]}
#   end
# end
#
# r = Many.new(xs).bind { |x| Many.unit x.product(ys) }
# puts r.values.inspect
