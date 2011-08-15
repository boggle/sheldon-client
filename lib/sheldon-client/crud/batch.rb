class SheldonClient
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
        response = send_request( :put, batch_connections_url, @connections )
        response.code == '200' ? true : false
      end
    end
  end
end
