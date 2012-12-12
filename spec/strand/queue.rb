shared_examples_for "a queue" do

    # These specs are derived from rubyspec for ruby's standard Queue class

    context :enqueue do

        it "adds an element to the Queue" do
            q = Strand::Queue.new
            q.size.should == 0
            q << Object.new
            q.size.should == 1
            q.push(Object.new)
            q.size.should == 2
            q.enq(Object.new)
            q.size.should == 3
        end

    end

    context :dequeue do
        it "removes an item from the Queue" do
            q = Strand::Queue.new
            q << Object.new
            q.size.should == 1
            q.pop
            q.size.should == 0
        end

        it "returns items in the order they were added" do
            q = Strand::Queue.new
            q << 1
            q << 2
            q.deq.should == 1
            q.shift.should == 2
        end

        it "blocks until there are items in the queue" do
            q = Strand::Queue.new
            v = 0

            s = Strand.new do
                q.pop
                v = 1
            end

            v.should == 0
            q << Object.new
            s.join()
            v.should == 1
        end

        it "raises a StrandError if Queue is empty" do
            q = Strand::Queue.new
            lambda { q.pop(true) }.should raise_error(strand_exception)
        end
    end

    context :length do
        it "returns the number of elements" do
            q = Strand::Queue.new
            q.length.should == 0
            q << Object.new
            q << Object.new
            q.length.should == 2
        end
    end

    context :empty do
        it "returns true on an empty Queue" do
            q = Strand::Queue.new
            q.empty?.should be_true
        end

        it "returns false when Queue is not empty" do
            q = Strand::Queue.new
            q << Object.new
            q.empty?.should be_false
        end
    end

    context :num_waiting do
        it "reports the number of Strands waiting on the Queue" do
            q = Strand::Queue.new
            fibers = []

            5.times do |i|
                q.num_waiting.should == i
                f = Strand.new { q.deq }
                Strand.pass until f.status and f.status == 'sleep'
                fibers << f
            end

            fibers.each { q.enq Object.new }

            fibers.each { |f| Strand.pass while f.alive? }

            q.num_waiting.should == 0
        end
    end

    context :doc_example do
        it "handles the doc example" do
            queue = Strand::Queue.new

            producer = Strand.new do
                5.times do |i|
                    Strand.sleep rand(i/4) # simulate expense
                    queue << i
                    puts "#{i} produced"
                end            
            end

            consumer = Strand.new do
                5.times do |i|
                    value = queue.pop
                    Strand.sleep rand(i/8) # simulate expense
                    puts "consumed #{value}"
                end            
            end

            consumer.join
        end
    end
end
