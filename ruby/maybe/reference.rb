# Reference (non-monadic) code to be refactored using Maybe/Optional monad

# Example taking from Tom Stuart's "Refactoring Ruby with Monads"
# http://codon.com/refactoring-ruby-with-monads

Project = Struct.new(:creator)
Person  = Struct.new(:address)
Address = Struct.new(:country)
Country = Struct.new(:capital)
City    = Struct.new(:weather)

def weather_for(project)
  unless project.nil?
    creator = project.creator
    unless creator.nil?
      address = creator.address
      unless address.nil?
        country = address.country
        unless country.nil?
          capital = country.capital
          unless capital.nil?
            weather = capital.weather
          end
        end
      end
    end
  end
end

project1 = Project.new(Person.new(Address.new(Country.new(City.new("warm")))))
project2 = Project.new(Person.new(nil))

puts weather_for(project1).inspect
puts weather_for(project2).inspect
