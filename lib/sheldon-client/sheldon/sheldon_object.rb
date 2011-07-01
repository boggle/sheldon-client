require 'forwardable'
require 'active_support/hash_with_indifferent_access'


class SheldonClient
  class SheldonObject
    extend Forwardable

    attr_accessor  :id, :type, :payload, :sheldon_class
    def_delegators :payload, :[], :[]=

    def initialize( data_hash )
      data_hash.symbolize_keys!
      self.id      = data_hash[:id].to_i
      self.type    = data_hash[:type].to_s.underscore.to_sym
      self.payload = HashWithIndifferentAccess.new( data_hash[:payload] || {} )
    end

    def to_i
      self.id
    end

    def name
      payload[:name] || payload[:title] || payload[:username]
    end

    def save
      SheldonClient.update self, payload.to_hash
    end

    def ==(other)
      id == other.id && type == other.type && payload == other.payload &&
        sheldon_class == other.sheldon_class
    end
  end
end

require 'sheldon-client/sheldon/node'
require 'sheldon-client/sheldon/connection'
