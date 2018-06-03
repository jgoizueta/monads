require_relative 'monad2'

require 'uri'
require 'net/http'
require 'json'
require 'uri_template'

TOKEN = '0d1b9fed487c6127359ba92e7c1f77b66b234c72'

# async function
THREADS = []

def get_json_async(url, &success)
  THREADS << Thread.new do
    begin
      uri   = URI.parse(url)
      if (TOKEN)
        uri.query = [uri.query, "access_token=#{TOKEN}"].compact.join('&')
      end
      json  = Net::HTTP.get(uri)
      value = JSON.parse(json)
      puts "GOT: #{url}"
      success.call(value)
    rescue Exception => e
      puts "ERROR #{url}: #{e}"
    end
  end
end

def run_to_completion()
  # THREADS.each &:join # only good for our threads
  while Thread.list.size > 1
    Thread.list.each{ |t| t.join unless t == Thread.current } # not good enougth
  end
end


# Using our own thread handling
def get_json1(url)
  Promise.new(false) { |s, f| get_json_async(url, &s) }
end

# letting Promise handle threads...
# we don't know what threads need joining
def get_json(url)
  Promise.new(true) do |ok, err|
    begin
      uri   = URI.parse(url)
      if (TOKEN)
        uri.query = [uri.query, "access_token=#{TOKEN}"].compact.join('&')
      end
      json  = Net::HTTP.get(uri)
      value = JSON.parse(json)
      puts "GOT: #{url}"
      ok.call(value)
    rescue Exception => e
      puts "ERROR #{url}: #{e}"
      puts e.backtrace
      err.call(e)
    end
  end
end

def async()
  get_json_async('https://api.github.com/') do |urls|
    org_url_template = URITemplate.new(urls['organization_url'])
    org_url = org_url_template.expand(org: 'ruby')

    get_json_async(org_url) do |org|
      repos_url = org['repos_url']

      get_json_async(repos_url) do |repos|
        most_popular_repo = repos.max_by { |repo| repo['watchers_count'] }
        repo_url = most_popular_repo['url']

        get_json_async(repo_url) do |repo|
          contributors_url = repo['contributors_url']

          get_json_async(contributors_url) do |users|
            most_prolific_user = users.max_by { |user| user['contributions'] }
            user_url = most_prolific_user['url']

            get_json_async(user_url) do |user|
              puts "The most influential Rubyist is #{user['name']} (#{user['login']})"
            end
          end
        end
      end
    end
  end
end

# nested promises
get_json('https://api.github.com/').chain do |urls|
  org_url_template = URITemplate.new(urls['organization_url'])
  org_url = org_url_template.expand(org: 'ruby')
  get_json(org_url).chain do |org|
    repos_url = org['repos_url']
    get_json(repos_url).chain do |repos|
      most_popular_repo = repos.max_by { |repo| repo['watchers_count'] }
      repo_url = most_popular_repo['url']
      get_json(repo_url).chain do |repo|
        contributors_url = repo['contributors_url']
        get_json(contributors_url).chain do |users|
          most_prolific_user = users.max_by { |user| user['contributions'] }
          user_url = most_prolific_user['url']
          get_json(user_url).chain do |user|
            puts "The most influential #{repo['name']} contributor is #{user['name']} (#{user['login']}) of #{users.size} users"
          end
        end
      end
    end
  end
end

# chained promises
get_json('https://api.github.com/').chain do |urls|
  org_url_template = URITemplate.new(urls['organization_url'])
  org_url = org_url_template.expand(org: 'ruby')
  get_json(org_url)
end.chain do |org|
  repos_url = org['repos_url']
  get_json(repos_url)
end.chain do |repos|
  most_popular_repo = repos.max_by { |repo| repo['watchers_count'] }
  repo_url = most_popular_repo['url']
  get_json(repo_url)
end.chain do |repo|
  contributors_url = repo['contributors_url']
  get_json(contributors_url)
end.chain do |users|
  most_prolific_user = users.max_by { |user| user['contributions'] }
  user_url = most_prolific_user['url']
  get_json(user_url)
end.chain do |user|
  puts "The most influential Rubyist is #{user['name']} (#{user['login']})"
end

# unnesting with nested
get_json('https://api.github.com/').nested(
  ->(urls) {
    org_url_template = URITemplate.new(urls['organization_url'])
    org_url = org_url_template.expand(org: 'ruby')
    get_json(org_url)
  },
  ->(org) {
    repos_url = org['repos_url']
    get_json(repos_url)
  },
  ->(repos) {
    most_popular_repo = repos.max_by { |repo| repo['watchers_count'] }
    repo_url = most_popular_repo['url']
    get_json(repo_url)
  },
  ->(repo) {
    contributors_url = repo['contributors_url']
    get_json(contributors_url)

  },
  ->(users) {
    most_prolific_user = users.max_by { |user| user['contributions'] }
    user_url = most_prolific_user['url']
    get_json(user_url)
  },
  ->(urls, org, repos, repo, users, user) {
    puts "The most influential #{repo['name']} contributor is #{user['name']} (#{user['login']}) of #{users.size} users"
  }
)

# test Promise.all
urls = get_json('https://api.github.com/')
org = get_json('https://api.github.com/').chain do |urls|
  org_url_template = URITemplate.new(urls['organization_url'])
  org_url = org_url_template.expand(org: 'ruby')
  get_json(org_url)
end
Promise.all([urls, org]).then do |(u,o)|
  puts "URLS: #{u.size}"
  puts "ORG: #{o['login']}"
end

run_to_completion