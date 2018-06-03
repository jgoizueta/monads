# TODO: use flat_map and some type for pairs (we'd use tuple in Python)


require_relative 'monad'

xs = [1,2,3]
ys = [4,5]

class Tuple
  def initialize(*values)
    @tuple = values
  end
  def to_s
    "(#{@tuple*', '})"
  end
  def [](i)
    @tuple[i]
  end
  def self.[](*values)
    new *values
  end
  def inspect
    to_s
  end
  def to_a
    @tuple
  end
end

puts xs.flat_map { |x| ys.map { |y| [x,y] } }.inspect
puts "-"*80

p = ManyFlat.from(xs).then { |x| ManyFlat.from(ys).then { |y| [x, y] } }
puts p.value.inspect
puts " . . . . . . . "
p.then{ |v| puts v.inspect }
puts " . . . . . . . "
p = ManyFlat.from(xs).then { |x| ManyFlat.from(ys).then { |y| Tuple[x, y] } }
puts p.value.inspect

puts "-"*80

ManyFlat.from(xs).nested(
  ->(x) { ys },
  ->(x, y){ puts [x,y].inspect }
)

puts "="*80


p = Many.from(xs).then { |x| Many.from(ys).then { |y| [x, y] } }
puts p.value.inspect
puts " . . . . . . . "
p.then{ |v| puts v.inspect }

puts "-"*80

Many.from(xs).nested(
  ->(x) { ys },
  ->(x, y){ puts [x,y].inspect }
)

puts "="*80


p = Many2.from(xs).then { |x| Many2.from(ys).then { |y| [x, y] } }
puts p.value.inspect
puts " . . . . . . . "
p.then{ |v| puts v.inspect }

puts "-"*80

Many2.from(xs).nested(
  ->(x) { ys },
  ->(x, y){ puts [x,y].inspect }
)

puts "="*80

r = ManyFlat.from(xs).nested_with_results(
  ->(x) { ys },
  ->(x, y){ puts [x,y].inspect }
)
puts r.inspect

puts "="*80

r = ManyFlat.from(xs).nested_with_results(
  ->(x) { ys }
)
puts r.inspect
