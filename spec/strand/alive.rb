
shared_examples_for "Strand#alive?" do

    context "alive?" do
        it "can check it's own status" do
            StrandSpecs.status_of_current_strand.alive?.should == true
        end

        it "describes a sleeping strand" do
            StrandSpecs.status_of_sleeping_strand.alive?.should == true
        end

        it "describes a blocked strand" do
            StrandSpecs.status_of_blocked_strand.alive?.should == true
        end

        it "describes a completed strand" do
            StrandSpecs.status_of_completed_strand.alive?.should == false
        end

        it "describes a killed strand" do
            StrandSpecs.status_of_killed_strand.alive?.should == false
        end

        it "describes a strand with an uncaught exception" do
            StrandSpecs.status_of_strand_with_uncaught_exception.alive?.should == false
        end

        it "describes a dying running strand" do
            StrandSpecs.status_of_dying_running_strand.alive?.should == true
        end

        it "describes a dying sleeping strand" do
            StrandSpecs.status_of_dying_sleeping_strand.alive?.should == true
        end

        # No such thing as a "running" strand
        quarantine!() do  
            it "describes a running strand" do
                StrandSpecs.status_of_running_strand.alive?.should == true
            end

            it "return true for a killed but still running strand" do
                exit = false
                t = Strand.new do
                    begin
                        sleep
                    ensure
                        true while !exit # spin until told to exit
                    end
                end

                StrandSpecs.spin_until_sleeping(t)

                t.kill
                t.alive?.should == true
                exit = true
                t.join
            end
        end
    end
end
