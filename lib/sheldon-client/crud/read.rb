class SheldonClient
  class Read < Crud

    def self.fetch_sheldon_object( type, id )
      (type == :node) ? fetch_sheldon_node( id ) : fetch_sheldon_connection( id )
    end

    def self.fetch_sheldon_node( node_id )
      response = send_request( :get, node_url(node_id) )
      response.code == '200' ? Node.new( JSON.parse(response.body) ) : nil
    end

    def self.fetch_edges( node_id, type )
      response = send_request( :get, node_connections_url(node_id, type) )
      response.code == '200' ? connection_collection( JSON.parse(response.body) ) : false
    end

    def self.fetch_neighbours( from_id, type )
      response = send_request( :get, neighbours_url(from_id, type) )
      response.code == '200' ? node_collection( JSON.parse(response.body) ) : false
    end
  end
end
