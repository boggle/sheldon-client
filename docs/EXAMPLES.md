Sheldon-Client Examples
===

Working with Nodes
---

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


Fetch connections from a node
----

    SheldonClient.node(17007).connection_types
    => [ :actors, :genre_taggings, :likes ]

    SheldonClient.node(17007).incoming_connection_types
    => [ :likes ]

    SheldonClient.node(17007).connections( :actors )
    => [ <Sheldon::Connection 64323 (Actor/17007->76423), ... ]

