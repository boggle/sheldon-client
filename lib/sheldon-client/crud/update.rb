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
      type, id = *sheldon_type_and_id_from_object( object )
      url = (type == :node) ? node_url( id.to_i ) : edge_url( id.to_i )
      send_request( :put, url, payload ).code == '200' ? true : false
    end

    def self.reindex_sheldon_object( object )
      type, id = *sheldon_type_and_id_from_object( object )
      url = (type == :node) ? node_url( id.to_i, :reindex ) : edge_url( id.to_i, :reindex )
      send_request( :put, url ).code == '200' ? true : false
    end


  end
end

