
shared_examples_for "strand local storage" do

    context "[]" do
        it "gives access to strand local values" do
            th = Strand.new do
                Strand.current[:value] = 5
            end
            th.join
            th[:value].should == 5
            Strand.current[:value].should == nil
        end

        it "is not shared across strands" do
            t1 = Strand.new do
                Strand.current[:value] = 1
            end
            t2 = Strand.new do
                Strand.current[:value] = 2
            end
            [t1,t2].each {|x| x.join}
            t1[:value].should == 1
            t2[:value].should == 2
        end

        it "is accessable using strings or symbols" do
            t1 = Strand.new do
                Strand.current[:value] = 1
            end
            t2 = Strand.new do
                Strand.current["value"] = 2
            end
            [t1,t2].each {|x| x.join}
            t1[:value].should == 1
            t1["value"].should == 1
            t2[:value].should == 2
            t2["value"].should == 2
        end

        it "raises exceptions on the wrong type of keys" do
            lambda { Strand.current[nil] }.should raise_error(TypeError)
            lambda { Strand.current[5] }.should raise_error(TypeError)
        end
    end

    context "[]=" do
        it "raises exceptions on the wrong type of keys" do
            lambda { Strand.current[nil] = true }.should raise_error(TypeError)
            lambda { Strand.current[5] = true }.should raise_error(TypeError)
        end
    end

    context "keys" do
        it "returns an array of the names of the thread-local variables as symbols" do
            th = Strand.new do
                Strand.current["cat"] = 'woof'
                Strand.current[:cat] = 'meow'
                Strand.current[:dog] = 'woof'
            end
            th.join
            th.keys.sort_by {|x| x.to_s}.should == [:cat,:dog]
        end
    end

    context "key?" do
        before :each do
            @th = Strand.new do
                Strand.current[:oliver] = "a"
            end
            @th.join
        end

        it "tests for existance of strand local variables using symbols or strings" do
            @th.key?(:oliver).should == true
            @th.key?("oliver").should == true
            @th.key?(:stanley).should == false
            @th.key?(:stanley.to_s).should == false
        end

        quarantine! do
            ruby_version_is ""..."1.9" do
                it "raises exceptions on the wrong type of keys" do
                    lambda { Strand.current.key? nil }.should raise_error(TypeError)
                    lambda { Strand.current.key? 5 }.should raise_error(ArgumentError)
                end
            end

        end

        # Ruby spec says 1.9 should raise TypeError
        it "raises exceptions on the wrong type of keys" do
            lambda { Strand.current.key? nil }.should raise_error(TypeError)
            lambda { Strand.current.key? 5 }.should raise_error(TypeError)
        end

    end
end

