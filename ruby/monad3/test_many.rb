require_relative 'monad'

# Test data
Blog     = Struct.new(:id, :categories)
Category = Struct.new(:id, :posts)
Post     = Struct.new(:id, :comments)

BLOGS = [
  Blog.new('B1', [
    Category.new('C1', [
      Post.new('P1', ['I love cats', 'I love dogs']),
      Post.new('P2', ['I love mice', 'I love pigs'])
    ]),
    Category.new('C2', [
      Post.new('P1', ['I hate cats', 'I hate dogs']),
      Post.new('P2', ['I hate mice', 'I hate pigs'])
    ])
  ]),
  Blog.new('B2', [
    Category.new('C1', [
      Post.new('P1', ['Red is better than blue'])
    ]),
    Category.new('C2', [
      Post.new('P1', ['Blue is better than red'])
    ])
  ])
]

def test3
  words = []
  Many.from(BLOGS)
  .then { |blog| blog.categories }
  .then { |category| category.posts }
  .then { |post| post.comments }
  .then { |comment| comment.split(/\s+/) }
  .then { |word| words << word }
  puts words.inspect

  puts "-"*80
  # nested
  Many.from(BLOGS).then { |blog|
    Many.from(blog.categories).then { |category|
      Many.from(category.posts).then { |post|
        Many.from(post.comments).then { |comment|
          puts "#{blog.id}/#{category.id}/#{post.id}/#{comment}"
          Many.from(comment)
        }
      }
    }
  }
end

puts "-"*80
test3

# solve the nesting problem (avoid the pyramids of doom)
# (Haskell solves that problem with its syntax without delimiters and even further with do notation)

puts ">"*80

# we can access nested results only at the end:
Many.new(BLOGS).nested(
  ->(blog){ blog.categories },
  ->(category){ category.posts },
  ->(post){ post.comments },
  ->(blog, category, post, comment) { puts "#{blog.id}/#{category.id}/#{post.id}/#{comment}" }
)
# or we can have them along the way:

puts "> >"*30

Many.new(BLOGS).nested(
  ->(blog){ blog.categories },
  ->(blog, category){ category.posts },
  ->(blog, category, post){ post.comments },
  ->(blog, category, post, comment) { puts "#{blog.id}/#{category.id}/#{post.id}/#{comment}" }
)


# test Monad.all
puts "/"*80

words = Many.from(BLOGS)
.then { |blog| blog.categories }
.then { |category| category.posts }
.then { |post| post.comments }
.then { |comment| comment.split(/\s+/) }
.then { |word| word }
blogs = Many.from(BLOGS)
maybe = Maybe.from(nil)
const = Monad.from(123)
Monad.all([blogs, maybe, words, const]).then do |(b, m, w, c)|
  puts "BLOGS: #{b.map(&:id).inspect}"
  puts "WORDS: #{w.size}"
  puts "? #{m.inspect}"
  puts "CONST #{c.inspect}"
end
