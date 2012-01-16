require 'json'
require 'active_support/inflector'
require 'forwardable'
require 'elastodon'

require 'sheldon-client/crud/crud'
require 'sheldon-client/crud/batch'
require 'sheldon-client/sheldon/status'
require 'sheldon-client/sheldon/schema'
require 'sheldon-client/sheldon/statistics'
require 'sheldon-client/sheldon/traverse'


require 'sheldon-client/configuration'
require 'sheldon-client/sheldon/sheldon_object'

module SheldonClient
  extend self
  extend SheldonClient::Configuration

  # Forward few status methods to the Status class. See
  # SheldonClient::Status for more information
  extend Forwardable
  def_delegators SheldonClient::Status, :status, :node_types, :connection_types
  def_delegators SheldonClient::Schema, :schema, :node_types, :connection_types
  def_delegators SheldonClient::Statistics, :statistics


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

  def create(type, options)
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
  def update( object, payload )
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
  def delete( object )
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
  def node( node_id )
    SheldonClient::Read.fetch_sheldon_object( :node, node_id )
  end


  #
  # Search for Sheldon Nodes. This will return an array of SheldonClient::Node
  # objects or an empty array.
  #
  # ==== Parameters
  #
  # type    - plural of any known sheldon node type like :movies or :genres.
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

  def search( query, options = {} )
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

  def fetch_edge_collection( uri )
    fetch_collection(uri)
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

  def fetch_collection( uri )
    SheldonClient::Read.fetch_collection( uri )
  end

  #
  # Fetches all the node ids of a given node type
  # Also all node's ids or connections's ids regardless of their type.
  #
  # === Parameters
  #
  #   * <tt>type</tt> - The node type
  #
  # === Examples
  #
  #   SheldonClient.all( :movies )
  #   => [1,2,3,4,5,6,7,8, ..... ,9999]
  #
  #   SheldonClient.all( :nodes )
  #   => [1,2,3,4,5,6,7,8, ..... ,9999]
  #
  #   SheldonClient.all( :connections )
  #   => [1,2,3,4,5,6,7,8, ..... ,9999]
  def all( type )
    SheldonClient::Read.fetch_node_type_ids(type)
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

  def reindex( object )
    SheldonClient::Update.reindex(object)
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
  def connection(object)
    SheldonClient::Read.fetch_sheldon_connection(object)
  end

  class << self
    alias :connections :connection
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
  def with_host( host, &block )
    begin
      SheldonClient.temp_host = host
      yield
    ensure
      SheldonClient.temp_host = nil
    end
  end

  # Fetches all the marks in sheldon and the marked nodes.
  #
  #  marks = SheldonClient.marked_nodes
  #  => { buzz_bucket: [ #<Sheldon::Node 204272 (Movie/My Neighbour Totoro)>,
  #                      #<Sheldon::Node 204233 (Movie/Big Tits Zombie)> ],
  #       buzz_people: [ #<Sheldon::Node 304272 (Person/Sora Aoi)>,
  #                      #<Sheldon::Node 304233 (Person/Al Paccino)> ] }

  def marked_nodes
    nodes = search(marked: true)
    marks = Hash.new do |h,k|
        h[k] = []
    end
    nodes.each do |node|
      node.marks.each do |mark|
        marks[mark] << node
      end
    end
    marks
  end

  # Returns a list of containers related to a given user, includes likes,
  # with the newest at the begining of the list.
  # You also can paginate the request using the per_page and page options.
  #
  # == Parameters
  #
  # <tt>user_id</tt> - You can pass an user object or the user id.
  # <tt>options</tt> - You can specify page and per_page.
  #
  # == Examples
  #
  #  => gonzo = SheldonClient.search('Gonzo Gonzales').first
  #
  #  => SheldonClient.stream(gonzo)
  # [ #<Sheldon::Node 204272 (Container/My Neighbour Totoro and his friends news)> ]
  #
  #  => SheldonClient.stream(gonzo.id)
  # [ #<Sheldon::Node 204272 (Container/My Neighbour Totoro and his friends news)> ]
  #
  #  => SheldonClient.stream(gonzo, page: 5, per_page: 5)
  # [ #<Sheldon::Node 204272 (Container/My Neighbour Totoro and his friends news)> ]
  #
  def stream(node, options = {})
    SheldonClient::Read.get_stream(node, options)
  end

  # Process the given block as a batch operation in sheldon
  #
  # == Parameters
  # <tt> size   </tt> - Lets you specify the size of the batch operation. By default it
  #                     is of 50 elements, so if you have more two or more request will
  #                     be issued.
  # <tt> block  </tt> - Receives a block which takes a batch as argument, in the batch
  #                     you can call create, with the type and info.
  #
  # == Example
  #
  # payload     = { weight: 1 }
  # connections = [ { from: 13 , to: 14, type: :likes, payload: payload },
  #                 { from: 13 , to: 16, type: :genre_taggings, payload: payload },
  #                 { from: 13 , to: 20, type: :actings, payload: payload } ]
  #
  # SheldonClient.batch do |batch|
  #   batch.create :connection, connections[0]
  #   batch.create :connection, connections[1]
  #   batch.create :connection, connections[2]
  # end
  #
  # SheldonClient.batch(2) do |batch|
  #   batch.create :connection, connections[0]
  #   batch.create :connection, connections[1]
  #   batch.create :connection, connections[2]
  # end
  #
  # Note
  # At the moment the creation in batch is just supported for connections.
  #
  def batch(size=50, &block)
    SheldonClient::Create.batch(size, &block)
  end

  def questionnaire(id)
    SheldonClient::Read.questionnaire id
  end

  def all_nodes
    SheldonClient::Read.all_nodes
  end

  def newest_containers
    SheldonClient::Read.newest_containers
  end

  def update_rule(rule, id)
    SheldonClient::Update.update_rule(rule, id)
  end

  def all_nodes_in_a_rule(rule)
    SheldonClient::Read.all_nodes_in_a_rule(rule)
  end

  ##
  # Fetch the user activity from sheldon
  #
  def activity(id)
    SheldonClient::Read.activities id
  end

end
