
require 'strand/strand'
require 'strand/local_storage'
require 'strand/mutex'
require 'strand/queue'
require 'strand/condition_variable'

shared_examples_for Strand do
    it_behaves_like "a strand"
    it_behaves_like "strand local storage"
    it_behaves_like "a mutex"
    it_behaves_like "a queue"
    it_behaves_like "a condition variable"
end
