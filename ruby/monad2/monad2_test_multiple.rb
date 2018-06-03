require_relative 'monad2'

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
  Multiple.from(BLOGS)
  .chain { |blog| blog.categories }
  .chain { |category| category.posts }
  .chain { |post| post.comments }
  .chain { |comment| comment.split(/\s+/) }
  .chain { |word| words << word }
  puts words.inspect

  puts "-"*80
  # nested
  Multiple.from(BLOGS).then { |blog|
    Multiple.from(blog.categories).then { |category|
      Multiple.from(category.posts).then { |post|
        Multiple.from(post.comments).then { |comment|
          puts "#{blog.id}/#{category.id}/#{post.id}/#{comment}"
          Multiple.from(comment)
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
Multiple.new(BLOGS).nested(
  ->(blog){ blog.categories },
  ->(category){ category.posts },
  ->(post){ post.comments },
  ->(blog, category, post, comment) { puts "#{blog.id}/#{category.id}/#{post.id}/#{comment}" }
)
# or we can have them along the way:

puts "> >"*30

Multiple.new(BLOGS).nested(
  ->(blog){ blog.categories },
  ->(blog, category){ category.posts },
  ->(blog, category, post){ post.comments },
  ->(blog, category, post, comment) { puts "#{blog.id}/#{category.id}/#{post.id}/#{comment}" }
)
