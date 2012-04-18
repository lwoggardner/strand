require 'spec_helper'
require 'condition_variable/broadcast'
require 'condition_variable/signal'
require 'condition_variable/wait'

def quarantine!(&specs)
    #Nothing
end

describe Strand::ConditionVariable do
    include EM::SpecHelper

    around(:each) do |example|
        em do
            ScratchPad.clear
            example.run
            done
        end
    end

    include_examples "ConditionVariable#signal"
    include_examples "ConditionVariable#wait"
    include_examples "ConditionVariable#broadcast"

  context "calling #wait with out of order resumes" do
    before(:each) do
      @cond = described_class.new
    end

    it "should block until signaled" do
      em do
        fiber = nil
        strand = Strand.new do
            fiber = Fiber.current
            @cond.wait
            Strand.yield.should == :not_the_signal
        end
        fiber.resume(:not_the_signal)
        @cond.signal
        strand.join
        done
      end
    end

    it "should block until timed out" do
      em do
        fiber = nil
        strand = Strand.new do
            fiber = Fiber.current
            @cond.wait(0.04)
            Strand.yield.should == :not_the_signal
        end
        
        EM.next_tick { fiber.resume(:not_the_signal) }
        strand.join
        done
      end
    end
  end


end

