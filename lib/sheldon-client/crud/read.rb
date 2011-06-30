class SheldonClient
  class Read < Crud

    def self.fetch_sheldon_object( type, id )
      (type == :node) ? fetch_sheldon_node( id ) : fetch_sheldon_connection( id )
    end

    def self.fetch_sheldon_node( node_id )
      response = send_request( :get, node_url(node_id) )
      response.code == '200' ? Node.new( JSON.parse(response.body) ) : nil
    end

    def self.fetch_sheldon_connection( object )
      if object.is_a?(Hash)
        unless object[:from] && object[:type]
          raise ArgumentError.new('You have to specify from and type')
        end

        return fetch_edges(object[:from], object[:type]) unless object[:to]

        url = node_connections_url(object[:from], object[:type], object[:to])
      else
        url = connnections_url( object )
      end

      response = send_request( :get, url)
      response.code == '200' ? Connection.new( JSON.parse(response.body) ) : false
    end

    def self.fetch_edges( node_id, type )
      response = send_request( :get, node_connections_url(node_id, type) )
      response.code == '200' ? connection_collection( JSON.parse(response.body) ) : false
    end

    def self.fetch_neighbours( from_id, type )
      response = send_request( :get, neighbours_url(from_id, type) )
      response.code == '200' ? node_collection( JSON.parse(response.body) ) : false
    end

    def self.fetch_high_scores(user, type = nil)
      validate_user(user)
      response = send_request(:get, user_high_scores_url(user, type))
      response.code == '200' ? connection_collection( JSON.parse(response.body) ) : false
    end

    def self.fetch_node_type_ids( type )
      #TODO:  validate type
      response = send_request(:get, node_type_ids_url(type))
      response.code == '200' ? JSON.parse(response.body) : false
    end

    private

    def self.validate_user(user)
      if user.is_a?(SheldonClient::Node) and !(user.type == :user)
        raise ArgumentError.new('Recommendations just works for users')
      end
    end
  end
end
