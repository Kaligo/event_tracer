require 'concurrent'

module EventTracer
  # This is an implementation of buffer storage. We use Concurrent::Array underneath
  # to ensure thread-safe behavior. Data is stored until certain size / interval
  # before flushing.
  #
  # Caveats: We should only store non-important data like logs in this buffer
  # because if a process is killed, the data in this buffer is lost.
  class Buffer
    # Buffer can store maximum 10 items.
    # Bigger size requires more memory to store, so choose a reasonable number
    DEFAULT_BUFFER_SIZE = 10
    # An item can live in buffer for at least 10s between each `Buffer#add` if the buffer is not full
    # If there are larger interval between the calls, it can live longer.
    DEFAULT_FLUSH_INTERVAL = 10

    def initialize(
      buffer_size: DEFAULT_BUFFER_SIZE,
      flush_interval: DEFAULT_FLUSH_INTERVAL
    )
      @buffer_size = buffer_size
      @flush_interval = flush_interval
      @buffer = Concurrent::Array.new
    end

    # Add an item to buffer
    #
    # @param item: data to be added to buffer
    # @return true if the item can be added, otherwise false
    def add(item)
      if add_item?
        buffer.push({ item: item, created_at: Time.now })
        true
      else
        false
      end
    end

    # Remove all existing items from buffer
    #
    # @return all items in buffer
    def flush
      data = []

      # NOTE: We need to use this to avoid race-condition
      buffer.cycle do
        data << buffer.shift[:item]
      end

      data
    end

    # This method is only used to facilitate testing
    def size
      buffer.size
    end

    private

      attr_reader :buffer_size, :flush_interval, :buffer

      def add_item?
        return false if buffer.size >= buffer_size

        # NOTE: we cannot use buffer.empty? then buffer.first here
        # due to race-condition when another thread flushes the buffer
        # right after buffer.empty? but before buffer.first is called.
        # If we have more complicated use case, we may need to start introducing
        # mutext.
        first_item = buffer.first
        first_item.nil? || first_item[:created_at] > Time.now - flush_interval
      end
  end
end
