# Base class for Monads
class Monad

  def initialize(v)
    @value = v
  end
  def to_s
    @value.inspect
  end

  # Wrapped sequencing (passes block that returns Monad to then, returns Monad)
  def chain(&blk)
    self.then do |v|
      r = blk[v]
      r.is_a?(Monad) ? r : self.class.from(r)
    end
  end
  # Note that the next implementation would work for some Monnads (Maybe), but no others (Many)
  # def chain(&blk)
  #   r = self.then(&blk)
  #   if r.is_a?(Monad)
  #     r
  #   else
  #     self.class.from(r)
  #   end
  # end

  # Derived classes must proide the naked then, which requires its block to return a Monad
end

# Maybe monad (optionality)
class Maybe < Monad
  def self.from(v = nil)
    new(v)
  end
  def then()
    if @value.nil?
      self
    else
      yield(@value)
    end
  end
end

# Testing the Maybe Monad
def test1
  #  chained ops (can use wrapped chain)
  v = { a: { b: { c: 11 } } }
  r = Maybe.from(v).chain{ |first| first[:a] }.chain{ |second| second[:b] }.chain{ |third| third[:c] }
  puts "r=#{r}"
  v = { a: { b: nil } }
  r = Maybe.from(v).chain{ |first| first[:a] }.chain{ |second| second[:b] }.chain{ |third| third[:c] }
  puts "r=#{r}"

  # nested ops; cannot used wrapped chain, needs to wrap each result
  v = { x: 100, a: { y:200, b: { c: 11 }} }
  r = Maybe.from(v).then{ |first|
    Maybe.from(first[:a]).then{ |second|
      Maybe.from(second[:b]).then{ |third|
        puts "x=#{first[:x]} y=#{second[:y]} c=#{third[:c]}"
        third[:c]
      }
    }
  }
  puts "r=#{r}"

  v = { x: 100, a: { y:200, b: nil} }
  r = Maybe.from(v).then{ |first|
    Maybe.from(first[:a]).then{ |second|
      Maybe.from(second[:b]).then{ |third|
        puts "x=#{first[:x]} y=#{second[:y]} c=#{third[:c]}"
        third[:c]
      }
    }
  }
  puts "r=#{r}"

end

test1()

# Experimental All implementation (access to multiple Monad results (inner values) simultaneously

# Aux class)
class Future
  def initialize(blk = nil)
    @done = false
    @blk = blk
    super nil
  end
  def set(value)
    @value = value
    @pending.each do |f|
      f.set value
    end
    @blo[@value] if @blk
    @done = true
  end
  def then(&blk)
    if @done
      blk[@value]
    else
      @pending << Future.new(blk)
    end
  end
end

# There's a smell with ALl:
# details that relate to async and many influence the implementation...
# regarding many, the problem is that given All.new(m1, m2, ...).then{...}
# any mi may contain multiple results (i.e. mi.then{} may call multiple times its block)
# and a Maybe monad may never call its block, so
# The intent was to use this as
# All.new([m1, m2, m3]).then{|(r1, r2, r3)| ... }
# it's then block would receive the results (inner values) of all the monads
# that's not easy if you want to make that apt for asynchronous Monads,
# since some monads have multiple results (Many) and others may have none,
# so we cannot now when all results are available easily (depending on blocks passed
# to each monad's then being called to provide the results)
# maybe all should be a method provided by Monad classes and returning a Monad
class All < Monad
  def initialize(monads)
    @pending = []
    @done = [false]*monads.size
    super(Array.new(monads.size){[]})
    monads.each_with_index do |monad, i|
      monad.chain do |result| # avoid chain and do not return Monad: break all the rules!
        @value[i] << result
        @done[i] = true
        if @done.all?
          # this is unreliable, since we don't know how results each entry may have
          # also some monads (e.g. Maybe) might never call this block
          while !@pending.empty?
            @pending.shift.setValue(@value)
          end
        end
        result
      end
    end
  end
  def then(&blk)
    if @done.all? || true
      blk[@value]
    else
      @pending << Future.new(&blk)
      @pending.last
    end
  end
end

# Many monad (multiplicity)

# Straightforward implementation: it needs to access inner values syncrhonously
class Many1 < Monad
  def self.from(value)
    new [value].flatten
  end
  attr_reader :value

  def then(&f) # f is expected to return a Many monad; otherwise use chain
    # TODO: this is ugly: it's exposing value
    # value should be obtained only through then/chain (think of an async Monad)
    # but... since this needs only be valid for Many ...
    r = @value.map(&f).flat_map(&:value)
    Many.from r
  end
  def to_s
    "M[#{@value}]"
  end
end

# Attempt to implement using All to avoid exposing inner value directly
class Many2 < Monad
  def self.from(value)
    new [value].flatten
  end

  def then(&f) # f is expected to return a Many monad; otherwise use chain
    monads = @value.map(&f)
    if monads.size > 1
      All.new(monads).then do |results|
        Many.from results
      end
    else
      monads.first
    end
  end
  def to_s
    "M[#{@value}]"
  end
end

# Tests for Many Monad
Many = Many1

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
  .chain { |blog| blog.categories }
  .chain { |category| category.posts }
  .chain { |post| post.comments }
  .chain { |comment| comment.split(/\s+/) }
  .chain { |word| words << word }
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

class Monad
  def nested(*functions, &blk)
    nested_recursive(self, [], functions, &blk)
  end
  private
  def nested_recursive(current, results, functions, &blk)
    last = current
    function = functions.first
    functions = functions[1..-1]
    if function
      result = nil
      current.then do |v|
        next_results = results + [v]
        if function.arity == 1
          result = function[v]
        else
          result = function[*next_results]
        end
        next_one = self.class.from(result)
        last = nested_recursive next_one, next_results, functions, &blk
        next_one
      end
      # results
    else
      blk[*results]
      # results
    end
    # no guarantee that last has been updated, it may still be current, because functions may execute asynchronously
    last
  end
end

# we can access nested results only at the end:
Many.new(BLOGS).nested(
  ->(blog){ blog.categories },
  ->(category){ category.posts },
  ->(post){ post.comments },
  ->(comment){ comment }
) do |blog, category, post, comment|
  puts "#{blog.id}/#{category.id}/#{post.id}/#{comment}"
end

# or we can have them along the way:

puts "> >"*30

Many.new(BLOGS).nested(
  ->(blog){ blog.categories },
  ->(blog, category){ category.posts },
  ->(blog, category, post){ post.comments },
  ->(blog, category, post, comment){ comment }
) do |blog, category, post, comment|
  puts "#{blog.id}/#{category.id}/#{post.id}/#{comment}"
end

# Eventually monad (asynchronicity)

# compose, then run on demand (lazy)
class Eventually < Monad
  def self.from(value)
    new { |success| success[value] }
  end
  def initialize(&block)
    super(block)
  end

  def run(&success)
    @value.call(success)
  end

  def then(&block)
    Eventually.new do |success|
      run do |value|
        block.call(value).run(&success)
      end
    end
  end
end

# run as you define (eager) (attempt)
class Eventually2 < Monad
  def self.from(value)
    new { |success| success[value] }
  end
  def initialize(&block)
    super(block)
    @resolved = false
    @result = nil
    @pending = []
    run do |result|
      puts "SUCCESS"
      @resolved = true
      @result = result
      @pending.each do |p|
        p.resolve(result)
      end
      @pending = []
    end
  end

  def resolve(value)
    @resolved = true
    @result = value
    @pending.each do |p|
      p.resolve(result)
    end
    @pending = []
    @value.call(->(v){v[value]})
  end

  def run(&success)
    @value.call(success)
  end

  def then(&block)
    if @resolved
      puts "ALREADY"
      block[@result]
    else
      puts "WAIT"
      e = Eventually2.new{|success|
        success[block]
      }
      @pending << e
      e
    end
  end
end

# Test the Eventually Monad

puts "="*80
require 'uri'
require 'net/http'
require 'json'
require 'uri_template'


# async function
THREADS = []

def get_json(url, &success)
  THREADS << Thread.new do
    uri   = URI.parse(url)
    json  = Net::HTTP.get(uri)
    value = JSON.parse(json)
    puts "GOT: #{url}"
    success.call(value)
  end
end

def run_to_completion()
  THREADS.each &:join
end

# example of what we intend to achieve (not using Monads here)
def intent()
  get_json('https://api.github.com/') do |urls|
    org_url_template = URITemplate.new(urls['organization_url'])
    org_url = org_url_template.expand(org: 'ruby')

    get_json(org_url) do |org|
      repos_url = org['repos_url']

      get_json(repos_url) do |repos|
        most_popular_repo = repos.max_by { |repo| repo['watchers_count'] }
        repo_url = most_popular_repo['url']

        get_json(repo_url) do |repo|
          contributors_url = repo['contributors_url']

          get_json(contributors_url) do |users|
            most_prolific_user = users.max_by { |user| user['contributions'] }
            user_url = most_prolific_user['url']

            get_json(user_url) do |user|
              puts "The most influential Rubyist is #{user['name']} (#{user['login']})"
            end
          end
        end
      end
    end
  end
end

# Helpers: Monad wrappers for async function

def get_json_eventually(url)
  Eventually.new { |s| get_json(url, &s) }
end

def get_json_eventually2(url)
  Eventually2.new { |s| get_json(url, &s) }
end


# Eventually.new{ |s| get_json('https://api.github.com/', &s) }
#   .chain do |urls|
#     puts urls.inspect
#     nil
#   end.run do |result|
#     puts result.inspect
#   end


# Eventually2.new{ |s| get_json('https://api.github.com/', &s) }
#   .chain do |urls|
#     puts urls.inspect
#     nil
#   end


  # get_json_eventually2('https://api.github.com/').chain do |urls|
  #   org_url_template = URITemplate.new(urls['organization_url'])
  #   org_url = org_url_template.expand(org: 'ruby')
  #   puts "URL: #{org_url}"
  #   get_json_eventually2(org_url)
  # end.chain do |org|
  #   puts org
  #   nil
  # end
if false
  get_json_eventually('https://api.github.com/').chain do |urls|
    org_url_template = URITemplate.new(urls['organization_url'])
    org_url = org_url_template.expand(org: 'ruby')
    puts "URL: #{org_url}"
    get_json_eventually(org_url)
  end.chain do |org|
    repos_url = org['repos_url']
    get_json_eventually(repos_url)
  end.chain do |repos|
    most_popular_repo = repos.max_by { |repo| repo['watchers_count'] }
    repo_url = most_popular_repo['url']
    get_json_eventually(repo_url)
  end.chain do |repo|
    contributors_url = repo['contributors_url']
    get_json_eventually(contributors_url)
  end.chain do |users|
    most_prolific_user = users.max_by { |user| user['contributions'] }
    user_url = most_prolific_user['url']
    get_json_eventually(user_url)
  end.run do |user|
    puts "The most influential Rubyist is #{user['name']} (#{user['login']})"
  end
end

puts ">" * 80

# what happens if we nest them? nesting seems impossible with this monad, because we rely on the linked
# monads returned by then
# we cann't do this because Monads are no chained one another for async execution

get_json_eventually('https://api.github.com/').chain do |urls|
  org_url_template = URITemplate.new(urls['organization_url'])
  org_url = org_url_template.expand(org: 'ruby')
  puts "URL: #{org_url}"
  get_json_eventually(org_url).chain do |org|
    repos_url = org['repos_url']
    get_json_eventually(repos_url).chain do |repos|
      most_popular_repo = repos.max_by { |repo| repo['watchers_count'] }
      repo_url = most_popular_repo['url']
      get_json_eventually(repo_url).chain do |repo|
        contributors_url = repo['contributors_url']
        get_json_eventually(contributors_url).chain do |users|
          most_prolific_user = users.max_by { |user| user['contributions'] }
          user_url = most_prolific_user['url']
          get_json_eventually(user_url).run do |user|
            puts "The most influential #{repo['name']} contributor is #{user['name']} (#{user['login']}) of #{users.size} users"
          end
        end
      end
    end
  end
end

if false
# try with nested... but how to run this??

get_json_eventually('https://api.github.com/').nested(
  ->(urls) {
    org_url_template = URITemplate.new(urls['organization_url'])
    org_url = org_url_template.expand(org: 'ruby')
    get_json_eventually(org_url)
  },
  ->(org) {
    repos_url = org['repos_url']
    get_json_eventually(repos_url)
  },
  ->(repos) {
    most_popular_repo = repos.max_by { |repo| repo['watchers_count'] }
    repo_url = most_popular_repo['url']
    get_json_eventually(repo_url)
  },
  ->(repo) {
    contributors_url = repo['contributors_url']
    get_json_eventually(contributors_url)

  },
  ->(users) {
    most_prolific_user = users.max_by { |user| user['contributions'] }
    user_url = most_prolific_user['url']
    get_json_eventually(user_url)
  }
) do |urls, org, repos, repo, users, user|
  puts "The most influential #{repo['name']} contributor is #{user['name']} (#{user['login']}) of #{users.size} users"
end.run{ |v|  puts "FINISH #{v}" } # innefective, since nested will return ther iniital promised, so only that one will execute

end


run_to_completion()

