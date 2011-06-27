class SheldonClient
  module Search

    #
    # Search for Sheldon Nodes. This will return an array of SheldonClient::Node Objects
    # or an empty array.
    #
    # ==== Parameters
    #
    # * <tt>type</tt> - plural of any known sheldon node type like :movies or :genres. Pass
    #   nil if you want to search all node-types.
    # * <tt>options</tt> - the search option that will be forwarded to lucene. This depends
    #   on the type, see below. options[:type] is reserved for the type of search you want
    #   to perform. Pass :exact or :fulltext for exact or fulltext matches.
    #
    # ==== Search Options
    #
    # Depending on the type of nodes you're searching for, different search options should
    # be provided. You can fetch the supported search keywords using the #status method
    # like that:
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
    def search( type, options = {}, search_type = :exact )
      options[:mode] = search_type unless options[:mode] or search_type == :fulltext
      uri = build_search_url( type, options )
      response = send_request( :get, uri )
      response.code == '200' ? parse_search_result(response.body) : []
    end


    #
    # Get the sheldon node associated with the given facebook-id. This will return
    # an array with all matched nodes or an empty array, if no such node is found.
    #
    # === Parameters
    #
    # <tt>fbid</tt> - The facebook id
    #
    # === Examples
    #
    # Fetch the sheldon node for facebook item 1234567
    #
    #   SheldonClient.facebook_item( '1234567' )
    #     => [#<Sheldon::Node 17007 (Movie/Tonari no Totoro)>]
    #
    def facebook_item( fbid )
      search( nil, { :facebook_ids => fbid }, :fulltext )
    end


    private

    def build_search_url( type, query_parameters )
      uri = Addressable::URI.parse( self.host + "/search" + (type.nil? ? "" : "/nodes/#{type}") )
      uri.query_values = Hash[*query_parameters.clone.map{|k,v| [k,v.to_s]}.flatten] # convert values to strings
      uri
    end



    def parse_search_result( json_string )
      JSON.parse( json_string ).map do |data|
        if is_edge?( data )
          Edge.new data
        else
          Node.new data
        end
      end
    end

    def parse_node(json_string)
      Node.new JSON.parse( json_string )
    end

    def is_edge?( data )
       data['from'] and data['to']
    end



    def build_edge_search_url( node_id, type )
      uri = Addressable::URI.parse( self.host + "/nodes/" + node_id.to_s + "/connections/" + type.to_s )
    end

    def build_node_url( node_id )
      uri = Addressable::URI.parse( self.host + "/nodes/" + node_id.to_s)
    end

    def build_url( uri )
      Addressable::URI.parse( self.host + uri )
    end
  end
end
