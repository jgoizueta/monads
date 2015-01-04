# Reference (non-monadic) code to be refactored using Maybe/Optional monad

# Example taking from Tom Stuart's "Refactoring Ruby with Monads"
# http://codon.com/refactoring-ruby-with-monads

Project = (creator) -> creator: creator
Person = (address) -> address: address
Address = (country) -> country: country
Country = (capital) -> capital: capital
City = (weather) -> weather: weather

weather_for = (project) ->
  if project
    creator = project.creator
    if creator
      address = creator.address
      if address
        country = address.country
        if country
          capital = country.capital
          if capital
            weather = capital.weather

project1 = Project Person Address Country City "warm"
project2 = Project Person null

console.log weather_for(project1)
console.log weather_for(project2)
