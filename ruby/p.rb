
# base Monad on Promise to let it handle error handling, asynchronicity?
# Promise behaviour is defined by its resolver passed to the constructor
# then has very specific behaviour to allow async/sunc resolution and chaining
# Monad behaviour is defined by from value constructor and then method
# Can we blend both together?

# better see https://github.com/dinshaw/promises/blob/master/lib/promise.rb
class P
  class F < P
    def initialize(resolve = nil, fail = nil)
      @resolver = @failer = nil
      @resolve = resolve || { |_value| }
      @fail = fail || { |_error| }
    end

    def [](resolver, failer = nil)
      @resolver = resolver
      @failer = failer
    end

    def resolve(value)
      @resolve[value]
      raise "race cond" if !@resolver
      @resolver[value]
    end

    def fail(error)
      @fail[error]
      raise "race cond" if !@failer
      @failer[error]
    end
  end

  def fulfill(value)
    while (p = @pending.shift)
      p.fulfill(result)
    end
    @result = result
    @state = :success
  end

  def reject(error)
    while (p = @pending.shift)
      p.reject(error)
    end
    @error = error
    @state = :failure
  end

  def initialize(behaviour, &blk)
    behaviour ||= blk
    @state = :pending
    @result = nil
    @error = nil
    @pending = []
    begin
      if behaviour.arity == 1
        behaviour[method(:fulfill)]
      else
        behaviour[method(:fulfill), method(:reject)]
      end
    rescue Exception => error
      reject(error)
    end
  end

  def self.resolve(value)
    new{ |success| success[value] }
  end

  def self.fail(error)
    new{ |success, failure| failure[value] }
  end

  def then(&receiver)
    case @state
    when :success
      value = receiver[@result]
      value.is_a?(Promise) ? value : P.resolve(value)
    when :failure
      # P.fail(@error)
      self
    when :pending
      pending(receiver, nil)
    end
  end

  def catch(&receiver)
    case @state
    when :success
      # return P.success(@result)
      return self
    when :failure
      value = receiver[@error]
      return value.is_a?(Promise) ? value : P.resolve(value)
    when :pending
      pending(nil, receiver)
    end
  end

  private

  def pending(s,e)
    # FIXME: race condition here?
    f = F.new(s, e)
    @pending << f
    if state != :pending && !@pending.empty
      raise "race condition"
    end
    return P.new(f)
  end


end