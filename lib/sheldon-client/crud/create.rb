module SheldonClient
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
    # from:    The source-node of the connection.
    # to:      The target-node of the connection.
    #
    # Payloads are not mandatory for connections but are strongly encouraged.
    #
    extend SheldonClient::HTTP
    extend SheldonClient::UrlHelper

    private

    def self.create_sheldon_object( type, options )
      type == :node ? create_node(options) : create_connection(options)
    end

    def self.create_node( options )
      response = send_request(:post, node_url(options[:type]), options[:payload] )
      parse_sheldon_response(response.body)
    end

    def self.create_connection( options )
      url = node_connections_url( options[:from], options[:type], to: options[:to] )
      response = send_request(:put, url, options[:payload] || {} )
      parse_sheldon_response(response.body)
    end

    def self.batch(size, &block)
      batch = SheldonClient::Batch.new(size)
      yield(batch)
      batch.process!
    end
  end
end
