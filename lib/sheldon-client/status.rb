class SheldonClient
  module Status
    TYPES = [:edge, :connection, :node]

    #
    # Get the sheldon status json hash including some basic
    # information with current edge and node statistics.
    #
    # === Example
    #
    # SheldonClient.status
    # => { ... }
    def status
      @status ||= get_sheldon_status
    end


    #
    # List of all supported node types of sheldon. You can get
    # additional information about the schema and the supported
    # payload elements by calling the #status method.
    #
    # === Example
    #
    # SheldonClient.node_types
    # => [ 'movie', 'genre', 'person', ... ]
    #
    # SheldonClient.status['nodes']['movie']['properties']
    # => { "name" => [ "case_insensitive_exact" ] }
    def node_types
      status['schema']['nodes'].keys
    end


    #
    # List of all supportes edge types of sheldon. Please note
    # that not all edges support connections from and to any
    # node. You can fetch additional information using the
    # #status method.
    #
    # === Example
    #
    # SheldonClient.edge_types
    # => [ 'likes', 'rating_similarity' ]
    #
    # SheldonClient.status['edges']['likes']['sources']
    # => [ 'user' ]
    #
    # SheldonClient.status['edges']['likes']['targets']
    # => [ 'movie', 'person' ]
    def edge_types
      status['schema']['connections'].keys
    end

    private

    def get_sheldon_status
      response = SheldonClient.send_request( :get, build_status_url )
      response.code == '200' ? status = JSON.parse( response.body ) : nil
    end
  end
end
