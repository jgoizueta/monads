# Reference code to be rewritten using a monadic idiom:

# Example taking from Tom Stuart's "Refactoring Ruby with Monads"
# http://codon.com/refactoring-ruby-with-monads

Blog     = Struct.new(:categories)
Category = Struct.new(:posts)
Post     = Struct.new(:comments)

def words_in(blogs)
  blogs.flat_map { |blog|
    blog.categories.flat_map { |category|
      category.posts.flat_map { |post|
        post.comments.flat_map { |comment|
          comment.split(/\s+/)
        }
      }
    }
  }
end


blogs = [
  Blog.new([
    Category.new([
      Post.new(['I love cats', 'I love dogs']),
      Post.new(['I love mice', 'I love pigs'])
    ]),
    Category.new([
      Post.new(['I hate cats', 'I hate dogs']),
      Post.new(['I hate mice', 'I hate pigs'])
    ])
  ]),
  Blog.new([
    Category.new([
      Post.new(['Red is better than blue'])
    ]),
    Category.new([
      Post.new(['Blue is better than red'])
    ])
  ])
]

puts words_in(blogs).inspect

# Using the same Many monad as in product.rb example:

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


def words_in(blogs)
  Many.new(blogs)
      .bind { |blog| Many.new(blog.categories) }
      .bind { |category| Many.new(category.posts) }
      .bind { |post| Many.new(post.comments) }
      .bind { |comment| Many.new(comment.split(/\s+/)) }.values
end

puts words_in(blogs).inspect
