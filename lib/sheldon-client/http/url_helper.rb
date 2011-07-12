require 'addressable/uri'

class SheldonClient
  module UrlHelper
    include ActiveSupport::Inflector

    def connnections_url(id)
      Addressable::URI.parse( SheldonClient.host + "/connections/#{id}" )
    end

    def node_connections_url( from, type, to = nil )
      if to.nil?
        path = "/nodes/#{from.to_i}/connections/#{type.to_s.pluralize}"
      else
        path = "/nodes/#{from.to_i}/connections/#{type.to_s.pluralize}/#{to.to_i}"

      end
      Addressable::URI.parse( SheldonClient.host + path )
    end

    def node_url( *args )
      if args[0].is_a?(Numeric) and args[1].nil?
        # e.g. node_url( 1 )
        path = "/nodes/#{args[0]}"
      elsif !args[1].nil? and args[1].is_a?(Symbol)
        # e.g. node_url( 1, :reindex )
        path = "/nodes/#{args[0]}/#{args[1]}"
      elsif !args[1].nil?
        # e.g. node_url( :movie, 2 )
        path = "/nodes/#{args[0].to_s.pluralize}/#{args[1]}"
      elsif  args[0].is_a?(Symbol) or args[0].is_a?(String)
        # e.g. node_url( :movie )
        path = "/nodes/#{args[0].to_s.pluralize}"
      end
      Addressable::URI.parse( SheldonClient.host + path )
    end

    def neighbours_url( from, type = nil )
      path = "/nodes/#{from}/neighbours"
      path = path + "/#{type.to_s.pluralize}" if type
      Addressable::URI.parse( SheldonClient.host + path )
    end

    def search_url( query, options = {} )
      if options[:type]
        path = "/search/nodes/" + options.delete(:type).to_s.pluralize
      else
        path = "/search"
      end
      query = { q: query } if query.is_a?(String)
      uri = Addressable::URI.parse( SheldonClient.host + path )
      uri.query_values = stringify_fixnums( query.update(options) )
      uri
    end

    def status_url
      Addressable::URI.parse( SheldonClient.host + "/status" )
    end

    def schema_url
      Addressable::URI.parse( SheldonClient.host + "/schema" )
    end

    def statistics_url
      Addressable::URI.parse( SheldonClient.host + "/statistics" )
    end

    def all_ids_url(type)
      Addressable::URI.parse( "#{SheldonClient.host}/ids/#{type}" )
    end

    def user_high_scores_url(user, type = nil)
      path = "/high_scores/users/#{user.to_i}"

      if type
        unless [:tracked, :untracked].include?(type)
          raise ArgumentError.new("The type can be tracked or untracked")
        end
        path = "#{path}/#{type.to_s}"
      end

      Addressable::URI.parse( SheldonClient.host + path )
    end

    def node_type_ids_url( type )
      path  = "/nodes/#{type.to_s.pluralize.to_sym}/ids"

      Addressable::URI.parse( SheldonClient.host + path )
    end

    def reindex_url( object )
      type, id = *get_type_and_id(object)
      path = "/#{type.to_s.pluralize.to_sym}/#{id.to_i}/reindex"

      Addressable::URI.parse( SheldonClient.host + path )
    end

    private

    def stringify_fixnums(hsh)
      hsh.each do |key, value|
        hsh[key] = value.to_s if value.is_a?(Fixnum)
      end
    end

    def get_type_and_id( object )
      if object.is_a?(Hash) and node = object[:node]
        [:node, node.to_i]
      elsif object.is_a?(Hash) and connection = object[:collection]
        [:collection, connection.to_i]
      else
        SheldonClient::Crud.sheldon_type_and_id_from_object( object )
      end
    end
  end
end
