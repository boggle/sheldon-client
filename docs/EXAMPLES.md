Sheldon-Client Examples
===

Working with Nodes
---

Create a node
----
    SheldonClient.create(:node, {type: :movie, payload: {title: 'My Neighbour Totoro'}}
    => #<Sheldon::Node 204272 (Movie/My Neighbour Totoro)>


Fetch a node and set/update payload elements.
----

    SheldonClient.node 17007
    => #<Sheldon::Node 17007 (Movie/Tonari no Totoro)>

    SheldonClient.node(17007)[:title]
    => "Tonari no Totoro"

    totoro = SheldonClient.node(17007)
    totoro[:title] = "My Neighbour Totoro"
    totoro.save
    => true

    SheldonClient.update( tororo, year: '1999', title: 'My Neighbour Totoro' )
    => true

 You can also update a node without requiring the node object

    SheldonClient.update( 123, year: '1999', title: 'Matrix' )
     => true

Delete  anode
----

    totoro = SheldonClient.node 17007
    => #<Sheldon::Node 17007 (Movie/Tonari no Totoro)>

    # With the node's id
    SheldonClient.delete( node: 17007 )

    #Passing the node
    SheldonClient.delete( totoro )

Fetch connections from a node
----

    SheldonClient.node(17007).connection_types
    => [ :actors, :genre_taggings, :likes ]

    SheldonClient.node(17007).incoming_connection_types
    => [ :likes ]

    SheldonClient.node(17007).connections( :actors )
    => [ <Sheldon::Connection 64323 (Actor/17007->76423), ... ]

    SheldonClient.connection(from:17007, type: :actors)
    => [ <Sheldon::Connection 64323 (Actor/17007->76423), ... ]

Fetch connections between nodes
----

    movie    = SheldonClient.node(17007)
    person   = SheldonClient.node(96781)
    SheldonClient.connection(from:movie, to:person, type: :actings)
     => #<Sheldon::Connection 206500 (acting/17007->96781)>

    movie    = SheldonClient.node(17007)
    person   = SheldonClient.node(96781)
    SheldonClient.connection(from:movie, to:person, type: :actings)
     => #<Sheldon::Connection 206500 (acting/17007->96781)>

    SheldonClient.connection(from:17007, to:96781, type: :actings)
     => #<Sheldon::Connection 206500 (acting/17007->96781)>

Reindexing a node
-----

     gozno = SheldonClient.search( username: 'gonzo gonzales' ).first

     SheldonClient.reindex(gozno)
     => true

     heldonClient.reindex(node: gozno.id).should eq(true)
     => true

     SheldonClient.reindex(node: gozno).should eq(true)
     => true

Add/Remove a mark to a node
-------
     gonzo = SheldonClient.search( username: 'gonzo gonzales' ).first
     gonzo.mark :trending_user
     => true

     gonzo.marks
     => [:trending_user]

     gonzo.marked?
     => true

Deleting mark

     gonzo = SheldonClient.search( username: 'gonzo gonzales' ).first
     gonzo.unmark :trending_user
     => true

     gonzo.marks
     => []

     gonzo.marked?
     => false

Getting all marked_nodes
------

     marks = SheldonClient.marked_nodes
     => { buzz_bucket: [ #<Sheldon::Node 204272 (Movie/My Neighbour Totoro)>,
                         #<Sheldon::Node 204233 (Movie/Big Tits Zombie)> ],
          buzz_people: [ #<Sheldon::Node 304272 (Person/Sora Aoi)>,
                         #<Sheldon::Node 304233 (Person/Al Paccino)> ] }



Working with Connections
---

Creating connections
----

    movie = SheldonClient.node 123
    user  = SheldonClient.node 321
    SheldonClient.create :connection, { from: user,
                                        to: movie,
                                        type: :likes,
                                        payload: { weight: '0.5' } }
     => #<Sheldon::Connection 546 (likes/321->123)>

    SheldonClient.create :connection, { from: 321,
                                        to: 123,
                                        type: :likes,
                                        payload: { weight: '0.5' } }
     => #<Sheldon::Connection 545 (likes/321->123)>

Updating a connection
----

    movie = SheldonClient.node 123
    user  = SheldonClient.node 321
    connection = SheldonClient.connection(from: user, to: movie, type: :likes)

    connection[:payload] = {weight: 0.6}
    connection.save
    => true

    SheldonClient.update (:connection, { from: user,
                                        to: movie,
                                        type: :likes,
                                        payload: { weight: 0.7 } })
     => true



Deleting connections
----

    movie = SheldonClient.node 123
    user  = SheldonClient.node 321
    connection = SheldonClient.connection(from: user, to: movie, type: :likes)
    => #<Sheldon::Connection 545 (likes/321->123)>

    SheldonClient.delete connection
    => true

    SheldonClient.delete(connection: {from: 321, to: 123, type:likes})
    => true

    # Using the connection id
    SheldonClient.delete(connection: 545)
    => true

Delete all the connection of a certain type

    user  = SheldonClient.node 321
    SheldonClient.delete(connection: {from: user, type:likes})
    => true


Reindexing a connection
------

     connection = SheldonClient.high_scores(192975).first

     SheldonClient.reindex(connection)
     => true

     SheldonClient.reindex(connection: connection.id)
     => true

     SheldonClient.reindex(connection: connection)
     => true

Fetching high scores
----

    user = SheldonClient.node 192975
     => #<Sheldon::Node 192975 (User/Janis Dever Whitmer)>

    SheldonClient.high_scores user
     => [#<Sheldon::Connection 476536 (affinity/192975->191202)>]

     SheldonClient.high_scores 192975
     => [#<Sheldon::Connection 476536 (affinity/192975->191202)>]


Sheldon Status/Schema/Statistics/Ids
-------------------------

Fetching Sheldon Client Status
----------------
Returns a hash with the information under /status

     SheldonClient.status

Fetching Sheldon Client Schema
----------------
Returns a hash with information about the nodes and connections

     SheldonClient.schema

Fetching Sheldon Client Statistics
----------

     SheldonClient.statistics

Fetching ids
-----------
You can fetch the ids of nodes with a given type or all the nodes and connections,
regardless of their type.

Fetch the ids of all existing connections, regardless of their type:

     SheldonClient.all( :connections )
      => [1,2,3,4,5,6,7,8, ..... ,9999]


Fetch the ids of all existing nodes, regardless of their type:

     SheldonClient.all( :nodes )
      => [1,2,3,4,5,6,7,8, ..... ,9999]

Fetch the ids of all nodes with type movie:

     SheldonClient.all( :movies )
      => [1,2,3,4,5,6,7,8, ..... ,9999]


Searching nodes
-------

General Query
-----

     SheldonClient.search('matrix')

Will make a query to sheldon that looks like this

     http://sheldon.host:2311/search?q=matrix

Searching by parameter
----

     SheldonClient.search( facebook_ids: '501730216' )

Searches over all node and connections type that share a same parameter name


Searching by parameter with a given mode
-----
You can do exact or fulltext search.

     SheldonClient.search(title:'The Matrix', :mode => :exact )
      => [#<Sheldon::Node 416 (Movie/The Matrix)>]

     SheldonClient.search(title:'matrix', :mode => :fulltext )
      => [ #<Sheldon::Node 416 (Movie/The Matrix)>,
           #<Sheldon::Node 1658 (Movie/The Matrix Revolutions)>,
           #<Sheldon::Node 1252 (Movie/The Matrix Reloaded)>

Searching by type
-------
Searches over the sheldon's nodes of the given type like.

      SheldonClient.search(title: 'Jennifer', type: :movie)
      => [#<Sheldon::Node 4396 (Movie/Jennifer 8)>, #<Sheldon::Node 10534 (Movie/Untitled Jennifer Lopez Comedy)>]


Getting the user stream
--------------

      => gonzo = SheldonClient.search('Gonzo Gonzales').first

      => SheldonClient.stream(gonzo)
     [ #<Sheldon::Node 204272 (Container/My Neighbour Totoro and his friends news)> ]

      => SheldonClient.stream(gonzo.id)
     [ #<Sheldon::Node 204272 (Container/My Neighbour Totoro and his friends news)> ]


Doing pagerank traversals
--------------
One type of our custom traversals are pagerank like calculations on
subgraphs of sheldon, starting from a user.

    => j = SheldonClient.search('Jannis Hermanns').first
    => SheldonClient::Traverse.pagerank j, :movies
    [ { :rank => 15, :node => #<Sheldon::Node 1234 (Movie/Snatch)>},
      { :rank => 5,  :node => #<Sheldon::Node 1234 (Movie/Big Lebowski)>},
      { :rank => 1,  :node => #<Sheldon::Node 1234 (Movie/Casablanca)>} ]

Valid types are `movies`, `people`, `buckets` and `containers`. The
result list is ordered by rank, and the ranks are not normalized yet.


Batch Operations
----------
At the moment sheldon client support batch opearations for connections.

      payload     = { weight: 1 }
      connections = [ { from: 13 , to: 14, type: :likes, payload: payload },
                      { from: 13 , to: 16, type: :genre_taggings, payload: payload },
                      { from: 13 , to: 20, type: :actings, payload: payload } ]


      SheldonClient.batch do |batch|
        batch.create :connection, connections[0]
        batch.create :connection, connections[1]
        batch.create :connection, connections[2]
      end
