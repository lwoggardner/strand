require 'strand/join'
require 'strand/exit'
require 'strand/wakeup'
require 'strand/status'
require 'strand/stop'
require 'strand/raise'
require 'strand/current'
require 'strand/alive'
require 'strand/pass'
require 'strand/value'
require 'strand/sleep'

shared_examples "a strand" do

    it "is the expected type of strand" do
        Strand.delegate_class(::Thread).should == strand_type
    end

    include_examples "Strand#current"
    include_examples "Strand#status"
    include_examples "Strand#exit"
    include_examples "Strand#join"
    include_examples "Strand#wakeup"
    include_examples "Strand#stop"
    include_examples "Strand#raise"
    include_examples "Strand#alive?"
    include_examples "Strand#pass"
    include_examples "Strand#value"
    include_examples "Strand#sleep"

    it "should have specs for Strand#list"
end
