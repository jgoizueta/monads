# Reference (non-monadic) code to be refactored using monads
# The request module should be installed with npm

# Example taking from Tom Stuart's "Refactoring Ruby with Monads"
# http://codon.com/refactoring-ruby-with-monads

request = require "request"

get_json = (url, success) ->
  request
    url: url
    json: true
    headers:
      'user-agent': 'node.js'
    (error, response, body) ->
      if !error && response.statusCode == 200
        success body
      else
        console.log error
        console.log response

find_in_array = (array, condition) ->
  for element in array
    return element if condition(element)
  return null

get_json 'https://api.github.com/', (urls) ->
  org_url = urls['organization_url'].replace('{org}', 'ruby')
  get_json org_url, (org) ->
    repos_url = org['repos_url']
    get_json repos_url, (repos) ->
      # most_popular_repo = repos.max_by { |repo| repo['watchers_count'] }
      max_watchers_count = Math.max (repo['watchers_count'] for repo in repos)...
      most_popular_repo = find_in_array repos, (repo) -> repo['watchers_count'] == max_watchers_count
      repo_url = most_popular_repo['url']
      get_json repo_url, (repo) ->
        contributors_url = repo['contributors_url']
        get_json contributors_url, (users) ->
          # most_prolific_user = users.max_by { |user| user['contributions'] }
          max_contributions = Math.max (user['contributions'] for user in users)...
          most_prolific_user = find_in_array users, (user) -> user['contributions'] == max_contributions
          user_url = most_prolific_user['url']
          get_json user_url, (user) ->
            console.log "The most influential Rubyist is #{user['name']} (#{user['login']})"
