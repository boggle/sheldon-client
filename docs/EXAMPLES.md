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

    SheldonClient.connection(17007, :actors)
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

    SheldonClient.update (connection, { from: user,
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


Sheldon Status/Schema/Statistics
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

