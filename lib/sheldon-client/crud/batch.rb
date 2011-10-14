module SheldonClient
  class Batch < Crud
    def initialize
      @connections = []
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
        response = send_request( :put, batch_connections_url, connections )
        true
      end
    end
  end
end
