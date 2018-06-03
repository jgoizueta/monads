# Monads with auto-wrapping in then (single accessor) and error catching

class Monad
  # default monad acts a identity
  def initialize(v, error=nil)
    @representation = v
    @error = error
    # keeping error in every monad seems overkill: a separate Monad class for Error could be better
  end

  attr_reader :representation

  def then(&blk)
    if @error
      self
    else
      begin
        wrap _on_success(&blk)
      rescue => err
        self.class.from_error(err)
      end
    end
  end

  def catch(&blk)
    if @error
      begin
        wrap _on_error(&blk)
      rescue => err
        # we rescue catch, which is useful if it tries to recover
        # but not if it's intention is to raise an exception;
        # for that raise_on_error or on_error should be used
        self.class.from_error(err)
      end
    else
      self
    end
  end

  def raise_on_error(exception = nil)
    raise exception || @error if @error
  end

  def on_error(&blk)
    blk[@error] if @error
  end

  def self.from(v)
    new v
  end

  def self.from_error(error)
    new nil, error
  end

  def self.all(monads)
    results = []
    count = [0]*monads.size
    monads.each_with_index do |monad, i|
      monad.then do |result|
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

  def nested(*functions)
    nested_recursive(self, [], functions)
  end

  def nested_with_results(*functions)
    nested_recursive(self, [], functions, [])
  end

  private

  def _on_success(&blk)
    # the base class acts as the identity monad
    blk[@representation]
  end

  def _on_error(&blk)
    blk[@error]
  end

  def nested_recursive(current, results, functions, return_values = nil)
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
        return_values << next_results if return_values && functions.empty?
        next_one =  result.is_a?(Promise) ? result : current.class.from(result)
        last = nested_recursive next_one, next_results, functions, return_values
        next_one
      end
    end
    return_values
  end

  def wrap(value)
    value.is_a?(Monad) ? value : self.class.from(value)
  end

  def unwrap()
    @representation
  end

end

# Maybe monad (optionality)
class Maybe < Monad
  private
  def _on_success
    if @representation.nil?
      self
    else
      wrap yield(@representation)
    end
  end
end

# Straightforward implementation: it needs to access inner values synchronously
class List < Monad
  def self.from(value)
    new [value].flatten
  end

  private
  def _on_success(&f)
    List.from @representation.map(&f).flat_map { |v| wrap(v).representation }
  end
end

# accept only arrays to avoid ambiguity and allow to hava items that are arrays:
# Many.from([x,y]) # two element collection
# Many.from([[x,y]]) # one element collection (an Array, [x,y])
# Many.from([x]) # one element collection
# Many.from([]) # zero element collection
# Many.from(nil) # zero element collection (for convenience)
class Many < Monad
  def self.from(value)
    value = [] if value.nil?
    raise "Many can only accept Arrays (#{value.inspect})" unless value.is_a?(Array)
    new value
  end

  private
  def _on_success(&f)
    Many.from @representation.map { |v| wrap(f[v]).representation }
  end
end

class Many2 < Monad
  def self.from(value)
    value = [] if value.nil?
    raise "Many can only accept Arrays (#{value.inspect})" unless value.is_a?(Array)
    new value
  end

  private
  def _on_success(&f)
    results = @representation.map(&f)
    wrapped = results.first.is_a?(Many2)
    if wrapped
      results = results.map(&:representation).flatten(1)
    end
    Many2.from results
  end
end

# Promise (asynchronicity, eventuality)
# implementation adapted from https://github.com/dinshaw/promises
# TODO: implement Promise by redefining _on_success, _on_error as an exercise
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

