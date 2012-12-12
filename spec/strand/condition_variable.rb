require 'strand/condition_variable/broadcast'
require 'strand/condition_variable/signal'
require 'strand/condition_variable/wait'

shared_examples_for "a condition variable" do
    include_examples "ConditionVariable#signal"
    include_examples "ConditionVariable#wait"
    include_examples "ConditionVariable#broadcast"
end

