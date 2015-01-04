# Reference code to be rewritten using a monadic idiom:

# Example taking from Tom Stuart's "Refactoring Ruby with Monads"
# http://codon.com/refactoring-ruby-with-monads

Blog = (categories) -> categories: categories
Category = (posts) -> posts: posts
Post = (comments) -> comments: comments

words_in = (blogs) ->
  words = []
  for blog in blogs
    for category in blog.categories
       for post in category.posts
         for comment in post.comments
           words = words.concat comment.split(' ')
  words

blogs = [
  Blog [
    Category [
      Post ['I love cats', 'I love dogs']
      Post ['I love mice', 'I love pigs']
    ],
    Category [
      Post ['I hate cats', 'I hate dogs']
      Post ['I hate mice', 'I hate pigs']
    ]
  ]
  Blog [
    Category [
      Post ['Red is better than blue']
    ]
    Category [
      Post ['Blue is better than red']
    ]
  ]
]


console.log words_in(blogs)

# Using the same Many monad as in product.rb example:

Many = (vs) ->
  bind: (f) -> Many (f(v).values for v in vs).reduce (a, b) -> a.concat b
  values: vs
Many.unit = (v) -> Many [v]


if true # newer versions of CoffeeScript accept this
         # (each .bind is out of the preceding lambda)

  words_in_many = (blogs) ->
    Many(blogs)
    .bind (blog) -> Many(blog.categories)
    .bind (category) -> Many(category.posts)
    .bind (post) -> Many(post.comments)
    .bind (comment) -> Many(comment.split(' '))
    .values

  console.log words_in_many(blogs)

else
  # but with version 1.1.2 we need to do this

  words_in_many = (blogs) ->
    Many(blogs)
    .bind (blog) -> Many(blog.categories)
    .bind (category) -> Many(category.posts)
    .bind (post) -> Many(post.comments)
    .bind (comment) -> Many(comment.split(' '))

  console.log words_in_many(blogs).values

  # or:
  words_in_many = (blogs) ->
    Many(blogs)
    .bind((blog) -> Many(blog.categories))
    .bind((category) -> Many(category.posts))
    .bind((post) -> Many(post.comments))
    .bind((comment) -> Many(comment.split(' ')))
    .values

  console.log words_in_many(blogs)
