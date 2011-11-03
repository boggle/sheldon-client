module SheldonClient
  class Batch < Crud
    def initialize(size)
      @connections = []
      @size = size
    end

    def create(type, object)
      case type
      when :connection
        @connections << object
      else
        raise ArgumentError.new("Batch operation is not supported for:#{type}")
      end
    end

    def update(type, object)
      create(type, object)
    end

    def process!
      unless @connections.empty?
        connections = @connections.sort_by{|c| c.symbolize_keys[:to].to_i }
        response = nil
        connections.each_slice(@size) do |slice|
          response = send_request( :put, batch_connections_url, slice )
        end
        true
      end
    end
  end
end
