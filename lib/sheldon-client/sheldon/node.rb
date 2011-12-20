# -*- coding: utf-8 -*-
module SheldonClient
  class Node < SheldonObject
    #
    # Naive Sheldon Node object implementation. You can access Sheldon
    # nodes via this simple proxy class. Please take a look at the
    # following examples
    #
    # === Examples
    #
    # Fetch a node from Sheldon
    #
    #   SheldonClient.node 17007
    #   => #<Sheldon::Node 17007 (Movie/Tonari no Totoro)>
    #
    #
    # ==== Access the Payload
    #
    # Access payload element of a node
    #
    #   SheldonClient.node(17007)[:title]
    #   => "Tonari no Totoro"
    #
    #
    # Update a payload element of a node. This will add aditional
    # payload elements. Please use Node#payload= if you want to set
    # the whole payload.
    #
    #   totoro = SheldonClient.node(17007)
    #   totoro[:title] = "My Neighbour Totoro"
    #   totoro.save
    #   => true
    #
    #
    # ==== Fetch Connections
    #
    # Fetch all valid connection types from this node. This includes
    # outgoing and incoming connection types. You can also fetch only
    # incoming or outgoing connections. See also
    # SheldonClient::Schema#connection_types for all availabel types.
    #
    #   SheldonClient.node(17007).connection_types
    #   => [ :actors, :genre_taggings, :likes ]
    #
    #   SheldonClient.node(17007).incoming_connection_types
    #   => [ :likes ]
    #
    #
    # Fetch all node-connections of specific type
    #
    #   SheldonClient.node(17007).connections :genre_taggings
    #   => [ #<Sheldon::Connection 509177 (GenreTagging/17007->190661)>, ... ]
    #
    #
    # ==== Degree (edge count)
    #
    # Return the count of edges. Takes the same options as #connections
    #
    #   SheldonClient.node(17007).degree(:all, direction: :incoming)
    #   SheldonClient.node(17007).degree(:likes)
    #
    # ==== Create Connections
    #
    # Create a connection. If the connection type is not valid for the
    # given object, a NoMethodError is thrown
    #
    #   chuck = SheldonClient.search( :person, name: 'chuck norris' ).first
    #   SheldonClient.node(17007).actors chuck
    #   => true
    #
    #   gonzo = SheldonClient.search( :user, username: 'gonzo gonzales' ).first
    #   gonzo.actors chuck
    #   => undefined method `actors' for #<Sheldon::Node 4 (User/Gonzo Gonzales)>
    #
    #
    # ==== Fetch Neighbours
    #
    # Neighbours are Sheldon Nodes that are connected to the current Node.
    # You can fetch all neighbours of the node or only neighbours of a
    # specific type. Please note that this might or might not take the
    # direction of the connection into account, as we're just relying on
    # the Sheldon resource.
    #
    #   SheldonClient.node(17007).neighbours
    #   => [ ... ]
    #
    #   SheldonClient.node(17007).neighbours( :likes )
    #   => [ <Sheldon::Node 6576 (User/Gonzo Gonzales)> ]
    #
    #
    # For your convenience, you can also access all neighbours of a
    # specific type using the connection-type as a method on the node
    # obeject.
    #
    #   SheldonClient.node(17007).neighbours( :likes )
    #   => [ <Sheldon::Node 6576 (User/Gonzo Gonzales)> ]
    #
    #   SheldonClient.node(17007).likes
    #   => [ <Sheldon::Node 6576 (User/Gonzo Gonzales)> ]

    #
    # ==== Create Neighbours
    #
    #
    include Elastodon::Node

    def to_s
      "#<Sheldon::Node #{id} (#{type.to_s.camelcase}/#{name})>"
    end

    def to_hash(opts = {})
      hash = HashWithIndifferentAccess.new({
        id:      self.id,
        type:    self.type,
        payload: self.payload
      })
      hash[:extra_search_data] = extra_search_data if opts[:include_search_data] && !extra_search_data.nil?
      hash
    end

    def connections( type = :all, opts = {} )
      Read.fetch_edges( self.id, type, opts )
    end

    def degree( type = :all, opts = {} )
      Read.fetch_degree( self.id, type, opts )['degree']
    end

    # syntactic sugar
    def subscription_count
      degree(:all_stories_subscriptions) + degree(:featured_stories_subscriptions)
    end

    def reason
      raw_data[:reason] || reason_from_path || {}
    end

    # fallback method, can be removed when sheldon returns reason instead of path
    def reason_from_path
      if raw_data[:path]
        path = raw_data[:path][1...-1] # cut first and last element
        type = case path.length
               when 1 then 'direct'
               when 2 then 'bucket'
               when 3 then 'bucket_hop'
               end
        {type: type, path: path}
      end
    end

    def marked?
      payload[:marked] || false
    end

    def marks
      (payload[:marks] || []).map(&:to_sym)
    end

    def mark( mark_name )
      payload[:marked] = true unless payload[:marked]
      unless marks.include?( mark_name.to_sym )
        payload[:marks] = marks << mark_name.to_sym
        save
      end
    end

    def unmark( mark_name )
      if payload[:marked] && payload[:marks].include?( mark_name.to_s )
        payload[:marks].delete(mark_name.to_s)
        if payload[:marks].empty?
          payload[:marked] = nil
          payload[:marks]  = nil
        end
        save
      else
        false
      end
    end

    def connection_types
      (outgoing_connection_types + incoming_connection_types).uniq.sort
    end

    def outgoing_connection_types
      SheldonClient::Schema.valid_connections_from( self.type )
    end

    def incoming_connection_types
      SheldonClient::Schema.valid_connections_to( self.type )
    end

    def neighbours(type = nil, direction = nil)
      Read.fetch_neighbours(self.id, type, direction)
    end

    def self.neighbours(id, type = nil, direction = nil)
      Read.fetch_neighbours(id, type, direction)
    end

    def reindex
      Update.reindex_sheldon_object( self )
    end

    def update_extra_search_data!
      self.extra_search_data = case type
                               when :person
                                 node = self.neighbours(:actings).first
                                 node ? node.name : ''
                               when :movie
                                 self.neighbours(:actings).first(2).map(&:name).join(', ')
                               when :bucket
                                 node = self.neighbours(:related_tos).reject do |n|
                                   [:container,:bucket].include? n.type
                                 end.first
                                 node ? node.name : ''
                               else
                                 ""
                               end
    end

    # Fetch the recently published containers about this node
    # === Parameters
    #
    # options    - You can specify page, per_page and type of stories.
    #
    # ===  Examples
    #
    # node = SheldonClient.node 205352
    # node.containers
    # => [ #<Sheldon::Node 205352 (Container/Who Are 2011’s Oscar Contenders to Date?)>,
    #      #<Sheldon::Node 205352 (Container/Who Are 2012’s Oscar Contenders to Date?)> ]
    #
    # node.containers(per_page:1, page:1, show: :featured_stories)
    # => [ #<Sheldon::Node 205352 (Container/Who Are 2011’s Oscar Contenders to Date?)>]
    #
    def containers(opts = {})
      opts ||= { page: 1, per_page: 10 }
      Read.get_node_containers(self, opts)
    end

    # Fetch suggestions about this node
    # === Parameters
    #
    # options    - You can specify page and per_page.
    #
    # ===  Examples
    #
    # node = SheldonClient.node 205352
    # node.node_suggestions
    # => [ #<Sheldon::Node 205352 (Movie/One Suggested Movie)>,
    #      #<Sheldon::Node 205352 (Movie/Another Suggested Movie)> ]
    #

    def node_suggestions(opts = {})
      opts ||= { page: 1, per_page: 10 }
      Read.get_node_suggestions(self, opts)
    end

    def subscribe(to, type)
      delete_previous_subscriptions(to)
      create_connection(type.to_sym, to, {})
    end

    private

    def delete_previous_subscriptions(to)
      featured = SheldonClient.connection(from: self.id, to: to.to_i, type: :featured_stories_subscriptions) rescue false
      all      = SheldonClient.connection(from: self.id, to: to.to_i, type: :all_stories_subscriptions) rescue false
      SheldonClient.delete featured if featured
      SheldonClient.delete all if all
    end

    def create_connection(connection_type, to_node, payload)
      SheldonClient::Create.create_sheldon_object :connection, from: self.id, to: to_node.to_i, type: connection_type, payload: payload
    end
  end
end
