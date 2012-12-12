
shared_examples_for "Strand#pass" do

    describe "pass" do
        it "returns nil" do
            Strand.pass.should == nil
        end
    end
end
