class SheldonClient
  class Schema < Crud

    def self.schema
      @schema ||= get_sheldon_schema
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

    def self.node_types
      schema['nodes'].keys.map(&:to_sym)
    end

    #
    # List of all supportes edge types of sheldon. Please note
    # that not all edges support connections from and to any
    # node. You can fetch additional information using the
    # #status method.
    #
    # === Example
    #
    # SheldonClient.connection_types
    # => [ 'likes', 'rating_similarity' ]
    #
    # SheldonClient.status['connections']['likes']['sources']
    # => [ 'user' ]
    #
    # SheldonClient.status['connections']['likes']['targets']
    # => [ 'movie', 'person' ]

    def self.connection_types
      schema['connections'].keys.map(&:to_sym)
    end

        #
    # List all valid +outgoing+ connections from a specific node-type.
    # This will return an array of connection-type symbols.
    #
    # === Parameter
    #
    # type   - The type of the source node for the connections
    #
    # === Example
    #
    #   SheldonClient.valid_connections_from( :user )
    #   => [ :likes ]

    def self.valid_connections_from( type )
      schema['connections'].inject([]) do |memo, (c_type, params)|
        memo << c_type if params['sources'].include?( type.to_s.pluralize )
        memo
      end.sort.map(&:to_sym)
    end


    #
    # List all valid +incoming+ connections from a specific node-type.
    # This will return an array of connection-type symbols.
    #
    # === Parameter
    #
    # type   - The type of the source node for the connections
    #
    # === Example
    #
    #   SheldonClient.valid_connections_to( :user )
    #   => [ ]

    def self.valid_connections_to( type )
      schema['connections'].inject([]) do |memo, (c_type, params)|
        memo << c_type if params['targets'].include?( type.to_s.pluralize )
        memo
      end.sort.map(&:to_sym)
    end

    private

    def self.get_sheldon_schema
      response = send_request( :get, schema_url )
      response.code == '200' ? schema = JSON.parse( response.body ) : nil
    end
  end
end
