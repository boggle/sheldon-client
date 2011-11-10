module SheldonClient
  class Batch < Crud
    def initialize(size)
      @connections = Hash.new do |hsh, key|
        hsh[key] = {}
      end
      @size = size
    end

    def create(type, object)
      case type
      when :connection
        object.symbolize_keys!
        @connections[object[:type]][object[:to].to_i] = object
      else
        raise ArgumentError.new("Batch operation is not supported for:#{type}")
      end
    end

    def update(type, object)
      create(type, object)
    end

    def process!
      unless @connections.empty?
        connections = @connections.values.map{|c| c.values }.flatten
        connections = connections.sort_by{|c| c[:to].to_i }
        connections.each_slice(@size) do |slice|
          send_request( :put, batch_connections_url, slice )
        end
        true
      end
    end
  end
end
