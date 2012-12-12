require 'spec_helper'
require 'strand/shared'

describe ::Thread do

    let (:strand_type) { ::Thread }
    let (:strand_exception) { ThreadError }

    around(:each) do |example|
       ScratchPad.clear
       example.run
    end

    it "should not be running in event machine" do
        Strand.event_machine?.should be_false
    end

    include_examples Strand
end

