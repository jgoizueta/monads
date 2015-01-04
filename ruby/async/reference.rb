# Reference (non-monadic) code to be refactored using monads
# The request module should be installed with npm

# Example taking from Tom Stuart's "Refactoring Ruby with Monads"
# http://codon.com/refactoring-ruby-with-monads

require 'uri'
require 'net/http'
require 'json'
require 'uri_template'

THREADS = []

def get_json(url, &success)
  THREADS << Thread.new do
    uri   = URI.parse(url)
    json  = Net::HTTP.get(uri)
    value = JSON.parse(json)
    success.call(value)
  end
end

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


THREADS.each &:join
