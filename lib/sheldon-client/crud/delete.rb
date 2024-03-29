module SheldonClient
  class Delete < Crud

    def self.delete_sheldon_object( object )
      type, params = *sheldon_type_and_id_from_object( object )
      url = (type == :node) ? node_url( params.to_i ) : delete_connections_url( params )
      send_request(:delete, url) and true
    end

    private

    def self.delete_connections_url( object )
      if object.is_a?(Hash)
        if object[:to]
          connection = SheldonClient.connection(object)
          connnections_url( connection.to_i )
        else
          node_connections_url(object[:from], object[:type])
        end
      else
        connnections_url( object.to_i )
      end
    end
  end
end
