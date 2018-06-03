require_relative 'monad'

# Testing the Maybe Monad
def test1
  #  chained ops
  v = { a: { b: { c: 11 } } }
  r = Maybe.from(v).then{ |first| first[:a] }.then{ |second| second[:b] }.then{ |third| third[:c] }
  r.then{ |v| puts v }
  v = { a: { b: nil } }
  r = Maybe.from(v).then{ |first| first[:a] }.then{ |second| second[:b] }.then{ |third| third[:c] }
  r.then{ |v| puts v }

  # nested ops
  v = { x: 100, a: { y:200, b: { c: 11 }} }
  r = Maybe.from(v).then{ |first|
    Maybe.from(first[:a]).then{ |second|
      Maybe.from(second[:b]).then{ |third|
        puts "x=#{first[:x]} y=#{second[:y]} c=#{third[:c]}"
        Maybe.from third[:c]
      }
    }
  }
  r.then{ |v| puts v }


  v = { x: 100, a: { y:200, b: nil} }
  r = Maybe.from(v).then{ |first|
    Maybe.from(first[:a]).then{ |second|
      Maybe.from(second[:b]).then{ |third|
        puts "x=#{first[:x]} y=#{second[:y]} c=#{third[:c]}"
        third[:c]
      }
    }
  }
  r.then{ |v| puts v }

end

test1()

puts "="*80

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

if RUBY_VERSION.to_f >= 2.3
  def weather_for_safe_op(project)
    project&.creator&.address&.country&.capital&.weather
  end

  puts weather_for_safe_op(project1).inspect
  puts weather_for_safe_op(project2).inspect
end

def weather_for_maybe(project)
  Maybe.from(project)
    .then{ |project| project.creator }
    .then{ |creator| creator.address }
    .then{ |address| address.country }
    .then{ |country| country.capital }
    .then{ |capital| capital.weather }
end

weather_for_maybe(project1).then{|w| puts w.inspect}
weather_for_maybe(project2).then{|w| puts w.inspect}


