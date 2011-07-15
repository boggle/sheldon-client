class SheldonClient
  class Search < Crud

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
    # General search
    #
    #   SheldonClient.search 'Matrix', mode: :fulltext
    #   SheldonClient.search { facebook_ids: 876543 }
    #
    # Search for a specific type
    #
    #   SheldonClient.search 'The Matrix', type: :movie
    #   SheldonClient.search { facebook_ids: 1234 }, type: :movie
    #   SheldonClient.search { title: 'Fear and Loathing in Las Vegas', production_year: 1998 }, type: :movie
    #
    #
    # Search for a specific genre
    #
    #    SheldonClient.search 'Action', type: :genre
    #
    #
    # And now with wildcards
    #
    #    SheldonClient.search 'Fist*', type: fulltext
    #

    def self.search( query, options = {} )
      return parse_search_result( Elastodon.emulate_sheldon_search(query, options) )
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
    def self.facebook_item( fbid )
      search( nil, { :facebook_ids => fbid }, :fulltext )
    end


    private

    def self.parse_search_result( json_string )
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

  end
end
