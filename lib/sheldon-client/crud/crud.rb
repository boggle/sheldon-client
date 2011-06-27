require 'active_support/core_ext/hash/keys'
require 'sheldon-client/http/http'
require 'sheldon-client/http/url_helper'

class SheldonClient
  class Crud
    extend SheldonClient::HTTP
    extend SheldonClient::UrlHelper

    def self.sheldon_type_and_id_from_object( object )
      if    object.is_a?(Hash) and object.keys.size == 1
        object.to_a.flatten
      elsif object.is_a?(Node) or object.is_a?(Connection)
        [ object.class.to_s.demodulize.underscore.to_sym, object.id ]
      else
        raise "unable to identify object #{object.inspect}"
      end
    end

    def self.connection_collection( json_array )
      json_array.map do |connection_data|
        Connection.new( connection_data )
      end
    end

    def self.node_collection( json_array )
      json_array.map do |connection_data|
        Node.new( connection_data )
      end
    end

  end
end

require 'sheldon-client/crud/create'
require 'sheldon-client/crud/read'
require 'sheldon-client/crud/update'
require 'sheldon-client/crud/delete'

require 'sheldon-client/crud/search'
