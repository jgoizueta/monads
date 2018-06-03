require_relative 'monad2'


# Testing the Maybe Monad
def test1
  #  chained ops (can use wrapped chain)
  v = { a: { b: { c: 11 } } }
  r = Maybe.from(v).chain{ |first| first[:a] }.chain{ |second| second[:b] }.chain{ |third| third[:c] }
  r.then{ |v| puts v }
  v = { a: { b: nil } }
  r = Maybe.from(v).chain{ |first| first[:a] }.chain{ |second| second[:b] }.chain{ |third| third[:c] }
  r.then{ |v| puts v }

  # nested ops; cannot used wrapped chain, needs to wrap each result
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
    .chain{ |project| project.creator }
    .chain{ |creator| creator.address }
    .chain{ |address| address.country }
    .chain{ |country| country.capital }
    .chain{ |capital| capital.weather }
end

weather_for_maybe(project1).then{|w| puts w.inspect}
weather_for_maybe(project2).then{|w| puts w.inspect}


