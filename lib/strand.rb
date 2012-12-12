require 'strand/version'
require 'thread'
require 'fiber'

# This module provides a shim between using standard ruby Threads
# and the thread-like behaviour for Fibers provided by classes in
# the Strand::EM module
# 
#   # For the Strand::EM classes to be available
#   # you must first load EventMachine
#   'require eventmachine'
#
#   'require strand'
#
#   t = Strand.new() do
#       # "t" is a standard ::Thread
#       ...something...
#   end
#
#   EventMachine.run do
#      t = Strand.new() do
#           # "t" is a ::Strand::EM::Thread
#           # which wraps a ::Fiber
#      end
#   end
#
#   # Outside of event machine 
#   t = Strand.new() do
#       # "t" is a raw ::Thread
#   end
#
# Code using Strand that may be used in both Fiber or Thread contexts
# should take care to rescue both {FiberError} and {ThreadError} in any
# exception handling code
#
# {::Thread} methods not implemented by Strand
#   * .main - although there is a root fiber it is not really equivalent to {::Thread.main}
#   * .start - not implemented
#   * #exclusive - not implemented  
#   * #critical - not implemented
#   * #set_trace_func - not implemented
#   * #safe_level - not implemented
#   * #priority - not implemented
module Strand

    # Test whether we have real fibers or a thread based fiber implmentation
    t = Thread.current
    ft = nil
    Fiber.new { ft = Thread.current }.resume

    ROOT_FIBER = Fiber.current
    REAL_FIBERS = ( t == ft )

    # Specifically try to enable use of Eventmachine if it is now available
    def self.reload()
        @em_class_map = if defined?(EventMachine) then enable_eventmachine() else nil end
    end

    # Private
    def self.enable_eventmachine
        return false unless defined?(EventMachine)

        require 'strand/em/thread.rb'
        require 'strand/em/queue.rb'

        # Classes if eventmachine has been previously loaded
        {
            ::Thread => Strand::EM::Thread,
            ::Kernel => Strand::EM::Thread,
            ::Mutex  => Strand::EM::Mutex,
            ::ConditionVariable => Strand::EM::ConditionVariable,
            ::Queue => Strand::EM::Queue
        }
    end

    # If EM already required then enable it, otherwise defer until first use
    reload()

    # Are we running in the EventMachine reactor thread
    #
    # For JRuby or other interpreters where fibers are implemented with threads
    # this will return true if the reactor is running and the code is called from
    # *any* fiber other than the root fiber
    def self.event_machine?
        @em_class_map = enable_eventmachine() if @em_class_map.nil?

        @em_class_map && EventMachine.reactor_running? &&
                ( EventMachine.reactor_thread? || (!REAL_FIBERS && ROOT_FIBER != Fiber.current))
    end

    def self.delegate_class(class_key)
        if self.event_machine? then @em_class_map[class_key] else class_key end
    end

    # ::Thread::list or EM::Thread::list
    def self.list
        delegate_class(::Thread).list()
    end

    # ::Thread::current or EM::Thread::current
    def self.current
        delegate_class(::Thread).current()
    end

    # ::Kernel::sleep or EM::Thread::sleep
    # Note that passing nil will sleep forever (where Kernel.sleep raises TypeError)
    def self.sleep(*args)
        # Kernel.sleep treats nil as an error, but we use it to indicate sleeping forever
        args.shift if args.length == 1 and args.first.nil?    
        delegate_class(::Kernel).sleep(*args)
    end

    # ::Thread::stop or EM::Thread::stop
    def self.stop()
        delegate_class(::Thread).stop() 
    end

    # ::Thread::pass or EM::Thread::pass
    def self.pass()
        delegate_class(::Thread).pass()
    end

    #TODO Is there some equivalence between the root Fiber and Thread.main?
    
    # Convenience to call Fiber.yield. Note the warning on EM::Thread::yield
    def self.yield(*args)
        Fiber.yield(*args)
    end

    # Behave like a class returning
    # an instance of ::Thread, or ::Strand::EM::Thread based on
    # whether the caller is within the EventMachine reactor 
    def self.new(*args,&block)
        delegate_class(::Thread).new(*args,&block)
    end

    module Mutex
        # Return a new ::Mutex or EM::Mutex
        def self.new(*args,&block)
            Strand.delegate_class(::Mutex).new(*args,&block)
        end
    end

    module ConditionVariable
        # Return a new ::ConditionVariable or EM::ConditionVariable
        def self.new(*args,&block)
            Strand.delegate_class(::ConditionVariable).new(*args,&block)
        end
    end

    module Queue
        # Return a new ::Queue or EM::Queue
        def self.new(*args,&block)
            Strand.delegate_class(::Queue).new(*args,&block)
        end
    end
end
