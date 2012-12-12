require "fiber"
require "eventmachine"
require 'strand/em/mutex'
require 'strand/em/condition_variable'

module Strand

    module EM

        #Acts like a ::Thread using Fibers and EventMachine
        class Thread

            @@strands = {}

            # The underlying fiber.
            attr_reader :fiber

            # Like ::Thread::list. Return an array of all EM::Threads that are alive.
            def self.list
                @@strands.values.select { |s| s.alive? }
            end

            # Like ::Thread::current. Get the currently running EM::Thread, eg to access thread local
            # variables
            def self.current
                @@strands[Fiber.current] || ProxyThread.new(Fiber.current)
            end

            # Alias for Fiber::yield
            # Equivalent to a thread being blocked on IO
            #
            # WARNING: Be very careful about using #yield with the other thread like methods
            # Specifically it is important
            # to ensure user calls to #resume don't conflict with the resumes that are setup via
            # EM.timer or EM.next_tick as a result of #::sleep or #::pass
            def self.yield(*args)
                Fiber.yield(*args)
            end

            # Like ::Kernel::sleep. Woken by an ::EM::Timer in +seconds+ if supplied
            def self.sleep(seconds=nil)

                raise TypeError, "seconds #{seconds} must be a number" unless seconds.nil? or seconds.is_a? Numeric
                n = Time.now

                strand = current
                timer = ::EM::Timer.new(seconds){ strand.__send__(:wake_resume) } unless seconds.nil?
                strand.__send__(:yield_sleep,timer)

                (Time.now - n).round()
            end

            # Like ::Thread::stop. Sleep forever (until woken)
            def self.stop
                self.sleep()
            end

            # Like ::Thread::pass.
            # The fiber is resumed on the next_tick of EM's event loop
            def self.pass
                strand = current
                ::EM.next_tick{ strand.__send__(:wake_resume) }
                strand.__send__(:yield_sleep)
                nil
            end

            # Create and run 
            def initialize(*args,&block)

                # Create our fiber.
                fiber = Fiber.new{ fiber_body(&block) }

                init(fiber)

                # Finally start the strand.
                fiber.resume(*args)
            end

            # Like ::Thread#join.
            #   s1 = Strand.new{ Strand.sleep(1) }
            #   s2 = Strand.new{ Strand.sleep(1) }
            #   s1.join
            #   s2.join
            def join(limit = nil)
                @mutex.synchronize { @join_cond.wait(@mutex,limit) } if alive?
                Kernel.raise @exception if @exception
                if alive? then nil else self end
            end

            # Like Fiber#resume. Refer to warnings on #::yield
            def resume(*args)
                #TODO  should only allow if @status is :run, which really means
                # blocked by a call to Yield
                fiber.resume(*args)
            end

            # Like ::Thread#alive? or Fiber#alive?
            def alive?
                fiber.alive?
            end

            # Like ::Thread#stop? Always true unless our fiber is the current fiber
            def stop?
                Fiber.current != fiber
            end

            # Like ::Thread#status
            def status
                case @status
                when :run
                    #TODO - if not the current fiber
                    # we can only be in this state due to a yield on the
                    # underlying fiber, which means we are actually in sleep
                    # or we're a ProxyThread that is dead and not yet
                    # cleaned up
                    "run"
                when :sleep
                    "sleep"
                when :dead, :killed
                    false
                when :exception
                    nil
                end
            end

            # Like ::Thread#value.  Implicitly calls #join.
            #   strand = Strand.new{ 1+2 }
            #   strand.value # => 3
            def value
                join and @value
            end

            # Like ::Thread#exit. Signals thread to wakeup and die
            def exit
                case @status
                when :sleep
                    wake_resume(:exit)
                when :run
                    throw :exit
                end
            end

            alias :kill :exit
            alias :terminate :exit

            # Like ::Thread#wakeup Wakes a sleeping Thread
            def wakeup
                Kernel.raise FiberError, "dead strand" unless status
                wake_resume() 
            end

            # Like ::Thread#raise, raise an exception on a sleeping Thread
            def raise(*args)
                if fiber == Fiber.current
                    Kernel.raise *args 
                elsif status
                    args << RuntimeError if args.empty?
                    wake_resume(:raise,*args)
                else
                    #dead strand, do nothing
                end
            end

            alias :run :wakeup


            # Access to "fiber local" variables, akin to "thread local" variables.
            #   Strand.new do
            #     ...
            #     Strand.current[:connection].send(data)
            #     ...
            #   end
            def [](name)
                raise TypeError, "name #{name} must convert to_sym" unless name and name.respond_to?(:to_sym)
                @locals[name.to_sym]
            end

            # Access to "fiber local" variables, akin to "thread local" variables.
            #   Strand.new do
            #     ...
            #     Strand.current[:connection] = SomeConnectionClass.new(host, port)
            #     ...
            #   end
            def []=(name, value)
                raise TypeError, "name #{name} must convert to_sym" unless name and name.respond_to?(:to_sym)
                @locals[name.to_sym] = value
            end

            # Like ::Thread#key? Is there a "fiber local" variable defined called +name+
            def key?(name)
                raise TypeError, "name #{name} must convert to_sym" unless name and name.respond_to?(:to_sym)
                @locals.has_key?(name.to_sym)
            end

            # Like ::Thread#keys The set of "strand local" variable keys
            def keys()
                @locals.keys
            end

            def inspect #:nodoc:
                "#<Strand::EM::Thread:0x%s %s" % [object_id, @fiber == Fiber.current ? "run" : "yielded"]
            end

            # Do something when the fiber completes.
            def ensure_hook(key,&block)
                if block_given? then 
                    @ensure_hooks[key] = block
                else
                    @ensure_hooks.delete(key)
                end
            end

            protected

            def fiber_body(&block) #:nodoc:
                # Run the strand's block and capture the return value.
                @status = :run

                @value = nil, @exception = nil
                catch :exit do
                    begin
                        @value = block.call
                        @status = :dead
                    rescue Exception => e
                        @exception = e
                        @status = :exception
                    ensure
                        run_ensure_hooks()
                    end
                end

                # Delete from the list of running stands.
                @@strands.delete(@fiber)

                # Resume anyone who called join on us.
                # the synchronize is not really necessary for fibers
                # but does no harm
                @mutex.synchronize { @join_cond.signal() }

                @value || @exception
            end

            private

            def init(fiber)
                @fiber = fiber
                # Add us to the list of living strands.
                @@strands[@fiber] = self

                # Initialize our "fiber local" storage.
                @locals = {}

                # Record the status
                @status = nil

                # Hooks to run when the strand dies (eg by Mutex to release locks)
                @ensure_hooks = {}

                # Condition variable and mutex for joining.
                @mutex =  Mutex.new()
                @join_cond = ConditionVariable.new()

            end
            def yield_sleep(timer=nil)
                @status = :sleep
                event,*args = Fiber.yield
                timer.cancel if timer
                case event
                when :exit
                    @status = :killed
                    throw :exit
                when :wake
                    @status = :run
                when :raise
                    Kernel.raise *args
                end
            end

            def wake_resume(event = :wake,*args)
                fiber.resume(event,*args) if @status == :sleep 
                #TODO if fiber is still alive? and status = :run
                # then it has been yielded from non Strand code. 
                # if it is not alive, and is a proxy strand then
                # we can signal the condition variable from here
            end

            def run_ensure_hooks()
                #TODO - better not throw exceptions in an ensure hook
                @ensure_hooks.each { |key,hook| hook.call }
            end
        end

        # This class is used if EM::Thread class methods are called on Fibers that were not created
        # with EM::Thread.new()
        class ProxyThread < Thread
           
            #TODO start an EM periodic timer to reap dead proxythreads (running ensurehooks)
            #TODO do something sensible for #value, #kill

            def initialize(fiber)
                init(fiber)
            end
        end
    end
end
