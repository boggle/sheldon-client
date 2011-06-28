class SheldonClient
  class Create < Crud

    # Create Sheldon Node and Connection objects.
    #
    # These options are mandatory to create a node object.
    #
    # type:    The type of the node. Please see SheldonClient#node_types for
    #          all supported types. An ArgumentError is raised if the type is
    #          not specified or known.
    # payload: The payload element. You must include a payload, otherwise an
    #          ArgumentError is raised.
    #
    #
    # These options are mandatory to create a connection object.
    #
    # type:    The type of the connection. Please see
    #          SheldonClient#connection_types for all supported types.
    #          An ArgumentError is raised if wether specified nor known.
    # from:    The source-node of the connection.
    # to:      The target-node of the connection.
    #
    # Payloads are not mandatory for connections but are strongly encouraged.
    #
    #
    # For your convienience you can also easily create connections using
    # the Node objects.
    #
    #     me     = SheldonClient.search( :users, username: 'Chuck Norris' )
    #     totoro = SheldonClient.search( :movies, title: 'Totoro' )
    #     me.likes totoro
    #

    extend SheldonClient::HTTP
    extend SheldonClient::UrlHelper

    VALID_TYPES = [ :node, :connection ]

    private

    def self.create_sheldon_object( type, options )
      validate_type( type )
      return create_node( options ) if type == :node
      return create_connection( options ) if type == :connection
    end

    def self.create_node( options )
      validate_node_options( options )
      response = send_request( :post, node_url( options[:type] ),
                                      options[:payload] )
      response.code == '201' ?
        parse_sheldon_response(response.body) : false
    end

    def self.create_connection( options )
      validate_connection_options( options )
      response = send_request( :put,  node_connections_url( options[:from], options[:type], options[:to] ),
                                      (options[:payload] || {}) )
      response.code == '200' ?
        parse_sheldon_response(response.body) : false
    end

    def self.validate_type( type )
      unless VALID_TYPES.include?( type.to_sym )
        raise ArgumentError.new('Unknown type')
      end
    end

    def self.validate_connection_options( options )
      raise ArgumentError.new("you must specify the type of connection") unless options[:type]
      raise ArgumentError.new("unknown connection type #{options[:type]}") unless
        SheldonClient.connection_types.include?( options[:type].to_s.pluralize.to_sym )
      raise ArgumentError.new("you must specify the source node") unless options[:from]
      raise ArgumentError.new("you must specify the target node") unless options[:to]
    end

    def self.validate_node_options( options )
      raise ArgumentError.new("you must specify the type of node") unless options[:type]
      raise ArgumentError.new("unknown node type #{options[:type]}") unless
        SheldonClient.node_types.include?( options[:type].to_s.pluralize.to_sym )
    end

    def self.dispatch_edge_creation(options)
      response = send_request( :put, create_edge_url( options ), options[:payload] )
      response.code == '200' ? true : false
    end

  end
end
