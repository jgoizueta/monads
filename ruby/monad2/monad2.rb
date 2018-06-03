# Monads with dual chain (auto-wrapping) and then accessors

class Monad
  # default monad acts a identity
  def initialize(v)
    @value = v
  end

  def then(&blk)
    blk[@value]
  end

  def self.from(v)
    new v
  end

  def self.all(monads)
    results = []
    count = [0]*monads.size
    monads.each_with_index do |monad, i|
      monad.chain do |result|
        count[i] += 1
        if count[i] == 1
          results[i] = result
        else
          results[i] = [results[i]] if count[i] == 2
          results[i] << result
        end
        result
      end
    end
    return from(results)
  end

  def chain(&blk)
    self.then do |v|
      r = blk[v]
      r.is_a?(Monad) ? r : self.class.from(r)
    end
  end

  def nested(*functions)
    nested_recursive(self, [], functions)
  end

  private

  def nested_recursive(current, results, functions)
    function = functions.first
    functions = functions[1..-1]
    if function
      result = nil
      current.chain do |v|
        next_results = results + [v]
        if function.arity == 1
          result = function[v]
        else
          result = function[*next_results]
        end
        next_one =  result.is_a?(Promise) ? result : current.class.from(result)
        last = nested_recursive next_one, next_results, functions
        next_one
      end
    end
  end

end

# Maybe monad (optionality)
class Maybe < Monad
  def then
    if @value.nil?
      self
    else
      yield(@value)
    end
  end
end

# Straightforward implementation: it needs to access inner values syncrhonously
class Many < Monad
  def self.from(value)
    new [value].flatten
  end
  attr_reader :value

  def then(&f) # f is expected to return a Many monad; otherwise use chain
    r = @value.map(&f).flat_map(&:value)
    Many.from r
  end
end

class Multiple < Monad
  def self.from(value)
    new [value].flatten
  end

  def then(&f) # f is expected to return a Many monad; otherwise use chain
    monads = @value.map(&f)
    if monads.size > 1
      monads.first.class.all(monads).then do |results| # INFINITE RECURSION!!
        Multiple.from results
      end
    else
      monads.first
    end
  end
end

# Promise (asynchronicity, eventuality)
# implementation adapted from https://github.com/dinshaw/promises
class Promise < Monad

  def self.all(promises)
    Promise.new do |fulfill, reject|
      results = []
      success = ->(result) do
        results << result
        fulfill.call(results) if results.size == promises.size
      end
      promises.each do |promise|
        promise.then(success, reject)
      end
    end
  end

  def self.any(promises)
    Promise.new do |fulfill, reject|
      count = promises.size
      on_error = ->(*) do
        count -= 1
        reject.call if count == 0
      end
      # For each promise, let it fulfill this promise,
      # if it fulfills. Otherwise, if all *promises come in rejected,
      # reject this promise.
      promises.each do |promise|
        promise.then(fulfill, on_error)
      end
    end
  end

  def self.resolve(value)
    Promise.new(false) { |fulfill, _| fulfill.call(value) }
  end

  def self.from(value)
    resolve value
  end

public

  def then(on_success = nil, on_error = nil, &blk)
    on_success ||= blk
    on_success ||= ->(x) {x}
    on_error ||= ->(x) {x}

    Promise.new(false) do |fulfill, reject|
      step = {
        fulfill: fulfill,
        reject: reject,
        on_success: on_success,
        on_error: on_error
      }
      if pending?
        @pending_steps << step
      else
        resolve step
      end
    end
  end

  def catch(on_error = nil, &blk)
    self.then(nil, on_error || blk)
  end

private

  def fulfill(value)
    return unless @state == :pending
    @state = :fulfilled
    @value = value
    resolve_steps
  end

  def fulfilled?
    @state == :fulfilled
  end

  def initialize(async = true)
    @state = :pending
    @value = nil
    @pending_steps = []
    exec = -> do
      begin
        yield method(:fulfill), method(:reject)
      rescue Exception => e
        reject(e)
      end
    end
    async ? Thread.new(&exec) : exec.call
  end

  def pending?
    @state == :pending
  end

  def reject(value)
    return unless @state == :pending
    @state = :rejected
    @value = value
    resolve_steps
  end

  def rejected?
    @state == :rejected
  end

  def resolve(step)
    callback = fulfilled? ? step[:on_success] : step[:on_error]
    result = callback.call(@value)

    if result.is_a? Promise
      # We have a promise that is still executing, so we need to tell it
      # what to do when complete
      result.then(step[:fulfill], step[:reject])
    else
      # We have a value (not a promise!) so we simply reuse the promise we
      # constructed in then when the "call" was originally setup. Our step has
      # the resolve and reject methods from that promise.
      (fulfilled? ? step[:fulfill] : step[:reject]).call result
    end
  end

  def resolve_steps
    @pending_steps.each { |step| resolve(step) }
    @pending_steps = nil
  end

  def value
    @value
  end
end

