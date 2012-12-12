shared_examples_for "Strand#wakeup" do

    context :wakeup do
        it "can interrupt Strand#sleep" do
            exit_loop = false
            after_sleep1 = false
            after_sleep2 = false

            t = Strand.new do

                # For Threads, this is an infinite running loop
                # but for EM::Thread this part of the test cannot
                # be simulated
                #while true
                #    break if exit_loop == true
                #end unless 

                Strand.sleep
                after_sleep1 = true

                Strand.sleep
                after_sleep2 = true
            end
          
            10.times { Strand.sleep(0.1) if t.status and t.status != "sleep" } 
            after_sleep1.should == false # t should be blocked on the first sleep
            t.send(:wakeup)

            10.times { Strand.sleep(0.1) if t.status and t.status != "sleep" } 
            after_sleep2.should == false # t should be blocked on the second sleep
            t.send(:wakeup)

            t.join
        end

        it "does not result in a deadlock" do
            t = Strand.new do
                10.times { Strand.stop }
            end

            while(t.status != false) do
                begin
                    t.send(:wakeup)
                rescue FiberError,ThreadError
                    # The strand might die right after.
                    t.status.should == false
                end
            end

            1.should == 1 # test succeeds if we reach here
        end

        it "raises a StrandError when trying to wake up a dead strand" do
            expected_error = Strand.event_machine? ? FiberError : ThreadError
            t = Strand.new { 1 }
            t.join
            lambda { t.wakeup }.should raise_error(expected_error)
        end
    end
end
