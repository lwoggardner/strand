
shared_examples_for "Strand#current" do
    context "current" do  
        it "returns a strand" do
            current = Strand.current
            current.should be_kind_of(strand_type)
        end

        it "returns the current strand" do
            t = Strand.new { Strand.current }
            t.value.should equal(t)
            Strand.current.should_not equal(t.value)
        end
    end
end
