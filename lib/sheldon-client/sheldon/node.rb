class SheldonClient
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

    def ==(other)
      self.to_indexed_json == other.to_indexed_json
    end

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

    def connections( type )
      if valid_connection_type?( type )
        Read.fetch_edges( self.id, type )
      else
        raise ArgumentError.new("unknown connection type #{type} for #{self.type}")
      end
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
      payload[:marked] = :true unless payload[:marked]
      unless marks.include?( mark_name.to_sym )
        payload[:marks] = marks << mark_name.to_sym
        save
      end
    end

    def unmark( mark_name )
      if payload[:marked] && marks.include?( mark_name )
        payload[:marks].delete(mark_name)
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

    def neighbours( type = nil )
      if valid_connection_type?( type ) or type.nil?
        Read.fetch_neighbours( self.id, type )
      else
        raise ArgumentError.new("invalid neighbour type #{type} for #{self.type}")
      end
    end

    def self.neighbours( id, type = nil )
      Read.fetch_neighbours( id, type )
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
                                 node = self.neighbours(:related_tos).reject(&its.type == :container).first
                                 node ? node.name : ''
                               else
                                 ""
                               end
    end

    private

    def create_connection( connection_type = '', to_node = nil, payload = nil )
      if to_node
        SheldonClient.create :connection, from: self.id, to: to_node.to_i, type: connection_type, payload: payload
      end
    end

    def valid_connection_type?( connection_type, type = :all )
      ctype =  connection_type.to_s.pluralize.to_sym
      if  type == :incoming
        incoming_connection_types.include?( ctype )
      elsif type == :outgoing
        outgoing_connection_types.include?( ctype )
      else
        connection_types.include?( ctype )
      end
    end

    def method_missing( *args )
      if valid_connection_type?( args[0] )
        if    args[1].nil?
          # e.g. node.likes
          return connections( args[0] )
        elsif valid_connection_type?( args[0], :outgoing ) and
              (args[1].is_a?(SheldonClient::Node) or args[1].is_a?(Numeric))
          # e.g. node.likes 123  <or>  node.likes SheldonClient.node(123)
          return create_connection( args[0], args[1], args[2] )
        end
      end
      super
    end
  end
end
