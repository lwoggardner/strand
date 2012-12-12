
shared_examples_for "Strand#sleep" do
    context "sleep" do
        it "pauses execution for approximately the duration requested" do
            duration = 0.1
            start = Time.now
            Strand.sleep duration
            (Time.now - start).should be_within(0.1).of(duration)
        end

        it "returns the rounded number of seconds asleep" do
            Strand.sleep(0.01).should be_kind_of(Integer)
        end
        it "raises a TypeError when passed a non-numeric duration" do
            # Kernel.sleep raises error for nil, Strand.sleep will sleep forever
            #lambda { Strand.sleep(nil)   }.should raise_error(TypeError)
            lambda { Strand.sleep('now') }.should raise_error(TypeError)
            lambda { Strand.sleep('2')   }.should raise_error(TypeError)
        end

        it "pauses execution indefinitely if not given a duration" do
            lock = Strand::Queue.new
            t = Strand.new do
                lock << :ready
                Strand.sleep
                5
            end
            lock.shift.should == :ready
            # wait until the thread has gone to sleep
            Strand.pass while t.status and t.status != "sleep"
            t.run
            t.value.should == 5
        end
       
        # Strand.sleep handles nil differently to kernel.sleep 
        it "pauses execution indefinitely if given a nil duration" do
            lock = Strand::Queue.new
            t = Strand.new do
                lock << :ready
                Strand.sleep(nil)
                5
            end
            lock.shift.should == :ready
            # wait until the thread has gone to sleep
            Strand.pass while t.status and t.status != "sleep"
            t.run
            t.value.should == 5
        end
        it "needs to be reviewed for spec completeness"
    end
end
