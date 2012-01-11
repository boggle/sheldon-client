module SheldonClient
  class Read < Crud

    def self.fetch_sheldon_object( type, id )
      (type == :node) ? fetch_sheldon_node( id ) : fetch_sheldon_connection( id )
    end

    def self.fetch_sheldon_node( node_id )
      response = send_request( :get, node_url(node_id) )
      Node.new( JSON.parse(response.body) )
    end

    def self.fetch_sheldon_connection( object )
      if object.is_a?(Hash)
        unless object[:from] && object[:type]
          raise ArgumentError.new('You have to specify from and type')
        end

        return fetch_edges(object[:from], object[:type], direction: object[:direction]) unless object[:to]

        url = node_connections_url(object[:from], object[:type], to: object[:to])
      else
        url = connnections_url( object )
      end

      response = send_request( :get, url)
      Connection.new( JSON.parse(response.body) )
    end

    def self.fetch_edges( node_id, type, opts = {} )
      response = send_request( :get, node_connections_url(node_id, type, opts) )
      connection_collection( JSON.parse(response.body) )
    end

    def self.fetch_degree( node_id, type, opts = {} )
      response = send_request( :get, node_degree_url(node_id, type, opts) )
      JSON.parse(response.body)
    end

    def self.fetch_neighbours( from_id, type, direction = nil )
      response = send_request( :get, neighbours_url(from_id, type, direction) )
      node_collection( JSON.parse(response.body) )
    end

    def self.fetch_node_type_ids( type )
      #TODO:  validate type
      if [:nodes, :connections].include?(type)
        response = send_request(:get, all_ids_url(type))
      else
        response = send_request(:get, node_type_ids_url(type))
      end
      JSON.parse(response.body).compact
    end

    def self.fetch_collection( uri )
      response = send_request( :get, Addressable::URI.parse( SheldonClient.host + uri ) )
      node_collection( JSON.parse(response.body) )
    end

    def self.get_stream( node, options = {} )
      response = send_request( :get, stream_url(node, options))
      node_collection( JSON.parse(response.body) )
    end

    def self.traverse( type, start_node_id, options = {} )
      response = send_request :get, traversal_url(type, start_node_id, nil, options)
      JSON.parse(response.body)
    end

    def self.pagerank( type, start_node_id, extra, options )
      response = send_request :get, traversal_url(type, start_node_id, extra, options)
      JSON.parse(response.body).map do |o|
        { :rank => o["rank"],
          :node => Node.new(o["node"]),
          :based_on => o["based_on"]
        }
      end
    end

    def self.get_node_containers(node, opts = {})
      response = send_request :get, node_containers_url(node, opts)
      node_collection( JSON.parse(response.body) )
    end

    def self.get_node_suggestions(node, opts = {})
      response = send_request :get, node_suggestions_url(node, opts)
      node_collection( JSON.parse(response.body) )
    end

    def self.questionnaire(id)
      response = send_request :get, questionnaire_url(id)
      Questionnaire.new( JSON.parse(response.body) )
    end

    def self.all_nodes
      response = send_request(:get, all_nodes_url)
      JSON.parse(response.body).compact
    end

    private

    def self.validate_user(user)
      if user.is_a?(SheldonClient::Node) and !(user.type == :user)
        raise ArgumentError.new('Recommendations just works for users')
      end
    end
  end
end
