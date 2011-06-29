require 'json'
require 'active_support/inflector'
require 'forwardable'

require 'sheldon-client/crud/crud'
require 'sheldon-client/sheldon/status'

require 'sheldon-client/configuration'
require 'sheldon-client/sheldon/sheldon_object'

class SheldonClient
  extend SheldonClient::Configuration

  @status = SheldonClient::Status

  # Forward few status methods to the Status class. See
  # SheldonClient::Status for more information
  class << self
    extend Forwardable
    def_delegators :@status, :status, :node_types, :connection_types
  end


  #
  # Create a Node or Connection in Sheldon. Please see SheldonClient::Create
  # for more information.
  #
  # === Parameters
  #
  # type    - The type of object you want to create. :node and
  #           :connection is supported.
  # options - The type-specific options. Please refer to
  #           SheldonClient::Create for more information. This
  #           should include a :type and might include a :payload
  #           element.
  #
  # ===  Examples
  #
  # Create a new node
  #
  #   SheldonClient.create :node, type: :movie, payload: { title: "Ran" }
  #
  # Create a new edge
  #
  #   SheldonClient.create :connection, type: 'like', from:    123, to:   321,
  #                         payload: { weight: 0.5 }

  def self.create(type, options)
    SheldonClient::Create.create_sheldon_object( type, options )
  end


  #
  # Updates the payload of a Node or Connection in Sheldon. Please see
  # SheldonClient::update for more information. Please also refer to the
  # SheldonClient::Node#update and SheldonClient::Node#[]= method.
  #
  # ==== Parameters
  #
  # object  - The object to be updated. This can be a Sheldon::Node, a
  #           Sheldon::Connection or a Hahs in the form of { <type>: <id> }
  # payload - The payload. The payload of the object will be replaces with
  #           this payload.
  #
  # ==== Examples
  #
  # Update a node
  #
  #   node = SheldonClient.node 123
  #   SheldonClient.update( node, year: '1999', title: 'Matrix' )
  #   => true
  #
  #   SheldonClient.update( { node: 123 }, title: 'Air bud' )
  #    => true
  #
  #   connection = SheldonClient.connection 123
  #   SheldonClient.update( connection, weight: 0.4 )
  #   => true
  #
  #   SheldonClient.update( { connection: {from:1, to:2, type: :like}}, weight: 0.4 )
  #    => true
  #
  def self.update( object, payload )
    if object.is_a?(SheldonClient::Connection)
      object = { connection: object }
    end

    SheldonClient::Update.update_sheldon_object( object, payload )
  end


  #
  # Deletes the Node or Connection from Sheldon. Please see
  # SheldonClient::Delete for more information
  #
  # ==== Parameters
  #
  # object  - The object to be updated. This can be a Sheldon::Node, a
  #           Sheldon::Connection or a Hahs in the form of { <type>: <id> }
  #
  # ==== Examples
  #
  # Delete a node from sheldon
  #
  #   SheldonClient.delete(node: 2011)
  #   => true
  #
  # Delete a connection from sheldon
  #
  #  SheldonClient.delete(connection: 201) // Non existant connection
  #   => false
  #
  # Delete a node's connections of a given type
  # SheldonClient.delete(connection: {from: 201, type: likes)
  #
  def self.delete( object )
    SheldonClient::Delete.delete_sheldon_object( object )
  end


  #
  # Fetch a single Node object from Sheldon. #node will return false if
  # the node could not be fetched.
  #
  # ==== Parameters
  #
  # node_id - The sheldon-id of the object to be fetched.
  #
  # ==== Examples
  #
  #   SheldonClient.node 17007
  #   => #<Sheldon::Node 17007 (Movie/Tonari no Totoro)>]
  #
  def self.node( node_id )
    SheldonClient::Read.fetch_sheldon_object( :node, node_id )
  end


  #
  # Search for Sheldon Nodes. This will return an array of SheldonClient::Node
  # objects or an empty array.
  #
  # ==== Parameters
  #
  # type    - plural of any known sheldon node type like :movies or :genres.
  #           Pass nil if you want to search all node-types.
  # options - the search option that will be forwarded to lucene. This depends
  #           on the type, see below. options[:type] is reserved for the type
  #           of search you want to perform. Pass :exact or :fulltext for
  #           exact or fulltext matches.
  #
  # ==== Search Options
  #
  # Depending on the type of nodes you're searching for, different search options
  # should be provided. You can fetch the supported search keywords using the
  # status method like that:
  #
  #    SheldonClient.status['nodes']['movie']['properties'].keys
  #    => [ 'title', 'production_year', 'moviemaster_id', 'facebook_ids', ... ]
  #
  #
  # ==== Examples
  #
  # Search for a specific movie
  #
  #   SheldonClient.search :movies, { title: 'The Matrix' }
  #   SheldonClient.search :movies, { title: 'Fear and Loathing in Las Vegas', production_year: 1998 }
  #
  # Search for a specific genre
  #
  #    SheldonClient.search :genres, { name: 'Action' }
  #
  # And now with wildcards
  #
  #    SheldonClient.search :movies, { title: 'Fist*', type: fulltext }
  #

  def self.search( query, options = {} )
    SheldonClient::Search.search( query, options )
  end

  # Fetch a collection of edges given an url
  #
  # ==== Parameters
  #
  # * <tt> url </tt> The url where to find the edges
  #
  # ==== Examples
  #
  #  e = SheldonClient.fetch_edges("/high_scores/users/13/untracked")
  #

  def self.fetch_edge_collection( uri )
    self.fetch_collection(uri)
  end

  # Fetch a collection of edges/nodes given an url.
  #
  # ==== Parameters
  #
  # * <tt> url </tt> The url where to find the objects
  #
  # ==== Examples
  #
  #  e = SheldonClient.fetch_collection("/high_scores/users/13/untracked") # fetches edges
  #  e = SheldonClient.fetch_collection("/recommendations/users/13/containers") # fetches nodes
  #

  def self.fetch_collection( uri )
    response = send_request( :get, build_url(uri) )
    response.code == '200' ? parse_search_result(response.body) : []
  end

  #
  # Fetches all the node ids of a given node type
  #
  # === Parameters
  #
  #   * <tt>type</tt> - The node type
  #
  # === Examples
  #
  #   SheldonClient.get_node_ids_of_type( :movies )
  #   => [1,2,3,4,5,6,7,8, ..... ,9999]
  #
  def self.get_node_ids_of_type( type )
    uri = build_node_ids_of_type_url(type)
    response = send_request( :get, uri )
    response.code == '200' ? JSON.parse( response.body ) : nil
  end


  #
  # Reindex an edge in Sheldon
  #
  # === Parameters
  #
  #  * <tt> edge_id </tt>
  #
  # === Examples
  #
  # SheldonClient.reindex_edge( 5464 )
  #

  def self.reindex_edge( edge_id )
    uri = build_reindex_edge_url( edge_id )
    response = send_request( :put, uri )
    response.code == '200' ? true : false
  end

  #
  # Fetches a connection
  #
  # === Parameters
  #
  # * object -  Can be the connection id or a hash specifyin from, to, and the type.
  #
  #
  # === Examples
  #
  # from = SheldonClient.search({title: 'The Matrix} )
  # to = SheldonClient.search({name: 'Action'})
  # connection = SheldonClient.connection( from:from, to:to, type: :genres )
  # => #<Sheldon::Connection 5 (GenreTagging/1->2)>
  #
  # Passing the connection id
  #
  # SheldonClient.connection 5
  # => #<Sheldon::Connection 5 (GenreTagging/1->2)>
  #
  # SheldonClient.connection (from: 1, type: :genres)
  #
  # => [#<Sheldon::Connection 5 (GenreTagging/1->2)>, #<Sheldon::Connection 6 (GenreTagging/1->3)>]
  #
  def self.connection(object)
    SheldonClient::Read.fetch_sheldon_connection(object)
  end

  #
  # Fetches all the high score edges for a user
  #
  # === Parameters
  #
  # <tt>id</tt> - The sheldon node id of the user
  #
  # === Examples
  #
  # SheldonClient.get_highscores 13
  # => [ {'id' => 5, 'from' => 6, 'to' => 1, 'payload' => { 'weight' => 5}} ]
  #
  def self.high_scores( id, type = nil )
    SheldonClient::Read.fetch_high_scores(id, type)
  end

  #
  # Fetchets all the recommendations for a user
  #
  # === Parameters
  #
  # <tt>id</tt> - The id of the sheldon user node
  #
  # === Examples
  #
  # SheldonClient.get_recommendations 4
  # => [{ id: "50292929", type: "Movie", payload: { title: "Matrix", production_year: 1999, has_container: "true" }}]
  #

  def self.recommendations( user_node )
    SheldonClient::Read.fetch_recommendations(user_node)
  end

  #
  # temporarily set a different host to connect to. This
  # takes a block where the given sheldon node should be
  # the one we're talking to
  #
  # == Parameters
  #
  # <tt>host</tt> - The sheldon-host (including http)
  # <tt>block</tt> - The block that should be executed
  #
  # == Examples
  #
  # SheldonClient.with_host( "http://www.sheldon.com" ) do
  #   SheldonClient.node( 1234 )
  # end
  def self.with_host( host, &block )
    begin
      SheldonClient.temp_host = host
      yield
    ensure
      SheldonClient.temp_host = nil
    end
  end

end
