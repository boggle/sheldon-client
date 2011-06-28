class SheldonClient
  class Delete < Crud

    def self.delete_sheldon_object( object )
      type, id = *sheldon_type_and_id_from_object( object )
      url = (type == :node) ? node_url( id.to_i ) : connnections_url( id.to_i )
      send_request( :delete, url ).code == '200' ? true : false
    end
  end
end
