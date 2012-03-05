# code borrowed from a response by user josh in the following post:
# http://stackoverflow.com/questions/1080993/pure-ruby-concurrent-hash

require 'thread'

class ConcurrentHash < Hash
  def initialize
    super
    @mutex = Mutex.new
  end

  def [](*args)
    @mutex.synchronize { super }
  end

  def []=(*args)
    @mutex.synchronize { super }
  end
end
