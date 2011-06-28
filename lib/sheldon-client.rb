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

  def self.update( object, payload )
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


  # Fetch all the nodes connected to a given node via edges of type <edge_type>
  #
  # ==== Parameters
  #
  # * <tt> node </tt> The node that we are going to fetch neighbours from
  # * <tt> type </tt> The egde type we are interesting in
  #
  # ==== Examples
  #
  #  m = SheldonClient.search(:movies, { title: '99 Euro*'} ).first
  #  e = SheldonClient.fetch_neighbours(m, 'genre_taggings')
  #
  #  g = SheldonClient.search(:genres, name: 'Drama').first
  #  e = SheldonClient.fetch_neighbours(m, 'genre_taggings')
  #

  def self.fetch_neighbours( node, type )
    node_id = node.is_a?(SheldonClient::Node) ? node.id : node

    fetch_edges( node_id, type ).map do |edge|
      fetch_node edge.to
    end
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




  # Deletes a edge from the database
  #
  # ==== Parameters
  # * <tt>id</tt> - The edge id we want to be deleted from the database
  #
  # ==== Examples
  #  SheldonClient.delete_edge(2011)
  #   => true
  #
  #  SheldonClient.delete_edge(201) //Non existant edge
  #   => false
  #

  def self.delete_edge(id)
    response = SheldonClient.send_request( :delete, build_edge_url( id ) )
    response.code == '200' ? true : false
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
  # Fetches an edge between two nodes of a given type
  #
  # === Parameters
  #
  # * <tt>from</tt> - The source node
  # * <tt>to</tt> - The target node
  # * <tt>type</tt> - The edge type
  #
  # === Examples
  #
  # from = SheldonClient.search( :movies, {title: 'The Matrix} )
  # to = SheldonClient.search( :genres, {name: 'Action'} )
  # edge = SheldonClient.edge( from, to, 'genres' )
  #

  def self.edge?( from, to, type)
    uri = build_fetch_edge_url( from, to, type )
    response = send_request( :get, uri )
    response.code == '200' ? Edge.new( JSON.parse( response.body )) : nil
  end

  #
  # Fetches a single edge from sheldon
  #
  # === Parameters
  #
  # * <tt>id</tt> - The edge id
  #
  # === Examples
  #
  # SheldonClient.edge 5
  # => #<Sheldon::Edge 5 (GenreTagging/1->2)>
  #

  def self.edge( id )
    uri = build_edge_url id
    response =send_request( :get, uri )
    response.code == '200' ? Edge.new( JSON.parse( response.body )) : nil
  end

  #
  # Updates an edge between two nodes of a given type
  #
  # === Parameters
  #
  # * <tt>from</tt> - The source node
  # * <tt>to</tt> - The target node
  # * <tt>type</tt> - The edge type
  # * <tt>options</tt> - The options that is going to be updated in the edge
  #   include the <tt>payload</tt>
  #
  # === Examples
  #
  # from = SheldonClient.search( :movies, {title: 'The Matrix} )
  # to = SheldonClient.search( :genres, {name: 'Action'} )
  # edge = SheldonClient.f( from, to, 'genres', { payload: { weight: '0.5' }} )

  def self.update_edge(from, to, type, options)
    response = SheldonClient.send_request( :put, build_fetch_edge_url( from, to, type ), options )
    response.code == '200' ? true : false
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

  def self.get_highscores( id, type=nil )
    response = SheldonClient.send_request( :get, build_high_score_url( id, type))
    response.code == '200' ? JSON.parse( response.body ) : nil
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

  def self.get_recommendations( id )
    response = SheldonClient.send_request( :get, build_recommendation_url(id) )
    response.code == '200' ? JSON.parse( response.body ) : nil
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
