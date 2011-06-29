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
      options[:mode] ||= :exact
      query = { q: query } if query.is_a?(String)
      uri = Addressable::URI.parse( SheldonClient.host + path )
      uri.query_values = stringify_fixnums( query.update(options) )
      uri
    end

    def status_url
      Addressable::URI.parse( SheldonClient.host + "/status" )
    end

    def user_recommendations_url(user)
      path = "/recommendations/user/#{user.to_i}/containers"

      Addressable::URI.parse( SheldonClient.host + path )
    end

    private

    def stringify_fixnums(hsh)
      hsh.each do |key, value|
        hsh[key] = value.to_s if value.is_a?(Fixnum)
      end
    end
  end
end
