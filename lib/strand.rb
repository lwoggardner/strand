require "fiber"
require "eventmachine"
require "strand/condition_variable"

class Strand

  @@strands = {}
  @yield_queues = {}
  

  # The strand's underlying fiber.
  attr_reader :fiber

  # Return an array of all Strands that are alive.
  def self.list
    @@strands.values
  end

  # Get the currently running strand.  Primarily used to access "strand local" variables.
  def self.current
    @@strands[Fiber.current]
  end
  
  # Yield the strand, but have EM resume it on the next tick.
  def self.pass
    self.safe_yield do |resumeable|
        EM.next_tick { resumeable.call }
    end
  end

  # EM/fiber safe sleep.
  def self.sleep(seconds)
    self.safe_yield do |resumeable|
        EM::Timer.new(seconds) { resumeable.call }
    end
  end
  
  # Equivalent to Fiber#yield 
  def self.yield(*args)
      if @yield_queues.has_key?(Fiber.current)
           head,tail = @yield_queues[Fiber.current]                   
           tail.unshift(*head); head.clear
           @yield_queues.delete(Fiber.current) if tail.size <= 1 
           return tail.shift if tail.size > 0
      end

      Fiber.yield(*args)
  end


  # Execute a block that calls resume in a later eventmachine tick
  # and then wait for that resume. Used by Strand#pass and Strand#sleep 
  #   Strand.safe_yield do |resumable|
  #     EM.timer(some_delay) { do_something() ; resumable.call }
  #   end
  def self.safe_yield()
     fiber, marker = Fiber.current, Object.new()
     resumable = lambda { fiber.resume(marker) }
     
     yield resumable

     resumed = self.yield()
     
     until marker.equal?(resumed)
        resumed = requeue(resumed)
     end

     resumed
  end
 
  # After Strand#yield, if the resumed item isn't the one you expected
  # then you can requeue it and wait for the next one
  def self.requeue(resumed)
      head, tail = @yield_queues[Fiber.current] ||= [ [], [] ]
      head << resumed
      if tail.size > 0 then tail.shift else Fiber.yield end
  end

  # Create and run a strand.
  def initialize(&block)

    # Initialize our "fiber local" storage.
    @locals = {}

    # Condition variable for joining.
    @join_cond = ConditionVariable.new

    # Create our fiber.
    @fiber = Fiber.new{ fiber_body(&block) }

    # Add us to the list of living strands.
    @@strands[@fiber] = self

    # Finally start the strand.
    resume
  end

  # Like Thread#join.
  #   s1 = Strand.new{ Strand.sleep(1) }
  #   s2 = Strand.new{ Strand.sleep(1) }
  #   s1.join
  #   s2.join
  def join
    @join_cond.wait if alive?
    raise @exception if @exception
    true
  end

  # Like Fiber#resume.
  def resume(*args)
      @fiber.resume(*args)
  end

  # Like Thread#alive? or Fiber#alive?
  def alive?
    @fiber.alive?
  end

  # Like Thread#value.  Implicitly calls #join.
  #   strand = Strand.new{ 1+2 }
  #   strand.value # => 3
  def value
    join and @value
  end

  # Access to "strand local" variables, akin to "thread local" variables.
  #   Strand.new do
  #     ...
  #     Strand.current[:connection].send(data)
  #     ...
  #   end
  def [](name)
    @locals[name.to_sym]
  end

  # Access to "strand local" variables, akin to "thread local" variables.
  #   Strand.new do
  #     ...
  #     Strand.current[:connection] = SomeConnectionClass.new(host, port)
  #     ...
  #   end
  def []=(name, value)
    @locals[name.to_sym] = value
  end

  # Is there a "strand local" variable defined called +name+
  def key?(name)
    @locals.has_key?(name.to_sym)
  end

  # The set of "strand local" variable keys
  def keys()
    @locals.keys
  end

  def inspect #:nodoc:
    "#<Strand:0x%s %s" % [object_id, @fiber == Fiber.current ? "run" : "yielded"]
  end

protected
  
  def fiber_body(&block) #:nodoc:
    # Run the strand's block and capture the return value.
    begin
      @value = block.call
    rescue StandardError => e
      @exception = e
    end

    # Mark the strand as finished running.
    @finished = true

    # Delete from the list of running stands.
    @@strands.delete(@fiber)

    # Resume anyone who called join on us.
    @join_cond.signal

    @value || @exception
  end

end
