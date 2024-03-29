module SheldonClient
  class Update < Crud

    # Update Sheldon Node and Connection objects.
    #
    #
    #
    # For your convienience you can also easily update payload elements
    # the Node objects like this:
    #
    #
    def self.update_sheldon_object( object, payload )
      type, params = *sheldon_type_and_id_from_object( object )
      url = (type == :node) ? node_url( params ) : connection_update_url( params )
      send_request( :put, url, payload ) and  true
    end

    def self.repair_node(node_id)
      send_request( :put, repair_node_url(node_id), {} ) and  true
    end

    def self.repair_connection(connection_id)
      send_request( :put, repair_connection_url(connection_id), {} ) and  true
    end

    def self.initialize_connections_rules
      send_request( :put, initialize_connections_rules_url, {} ) and true
    end

    def self.reindex( object )
      send_request( :put, reindex_url(object) ) and true
    end

    def self.reindex_sheldon_object( object )
      type, id = *sheldon_type_and_id_from_object( object )
      url = (type == :node) ? node_url( id.to_i, :reindex ) : edge_url( id.to_i, :reindex )
      send_request( :put, url ) and true
    end


    private

    def self.connection_update_url( object )
      if object.is_a?(Hash)
        node_connections_url(object[:from], object[:type], to: object[:to])
      else
        node_connections_url(object.from_id, object.type, to: object.to_id)
      end
    end
  end
end

