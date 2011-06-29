class SheldonClient
  class Update < Crud

    # Update Sheldon Node and Connection objects.
    #
    #
    #
    # For your convienience you can also easily update payload elements
    # the Node objects like this:
    #
    #
    private

    def self.update_sheldon_object( object, payload )
      type, params = *sheldon_type_and_id_from_object( object )
      url = (type == :node) ? node_url( params ) : connection_update_url( params )
      send_request( :put, url, payload ).code == '200' ? true : false
    end

    def self.reindex_sheldon_object( object )
      type, id = *sheldon_type_and_id_from_object( object )
      url = (type == :node) ? node_url( id.to_i, :reindex ) : edge_url( id.to_i, :reindex )
      send_request( :put, url ).code == '200' ? true : false
    end


    private

    def self.connection_update_url( object )
      if object.is_a?(Hash)
        node_connections_url(object[:from], object[:type], object[:to])
      else
        node_connections_url(object.from_id, object.type, object.to_id)
      end
    end
  end
end

