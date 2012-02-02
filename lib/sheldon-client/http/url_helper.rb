require 'addressable/uri'

module SheldonClient
  module UrlHelper
    include ActiveSupport::Inflector

    def connnections_url(id)
      Addressable::URI.parse( SheldonClient.host + "/connections/#{id}" )
    end

    def node_connections_url( from, type, opts = {} )
      type = type == :all ? type.to_s : type.to_s.pluralize
      if opts[:to].nil?
        path = "/nodes/#{from.to_i}/connections/#{type}"
        path = "#{path}/#{opts[:direction]}" if opts[:direction]
      else
        path = "/nodes/#{from.to_i}/connections/#{type}/#{opts[:to].to_i}"
      end
      Addressable::URI.parse( SheldonClient.host + path )
    end

    def node_degree_url( from, type, opts = {} )
      node_connections_url(from, type, opts).tap do |uri|
        uri.path += '/degree'
      end
    end

    def node_url( *args )
      if is_id?(*args) and args[1].nil?
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

    def neighbours_url( from, type = nil, direction = nil)
      path = "/nodes/#{from}/neighbours"
      path = path + "/#{type.to_s.pluralize}" if type
      path = path + "/#{direction.to_s}" if direction
      Addressable::URI.parse( SheldonClient.host + path )
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

    def traversal_url(type, start_id, extra = nil, options = nil)
      e = extra ? "/#{extra}" : ''
      start_id = start_id.is_a?(SheldonClient::Node) ? start_id.id : start_id
      uri = Addressable::URI.parse( SheldonClient.host + "/traversals/#{type}/users/#{start_id}#{e}" )
      uri.query_values = stringify_fixnums( options ) unless !options or options.empty?
      uri
    end

    def all_ids_url(type)
      Addressable::URI.parse( "#{SheldonClient.host}/ids/#{type}" )
    end

    def all_nodes_url
      Addressable::URI.parse("#{SheldonClient.host}/specials/graphs/nodes/all")
    end

    def all_connections_url(clazz)
      Addressable::URI.parse("#{SheldonClient.host}/specials/graphs/connections/#{clazz}/all")
    end

    def newest_containers_url
      Addressable::URI.parse( "#{SheldonClient.host}/specials/graphs/containers" )
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

    def repair_node_url(id)
      Addressable::URI.parse( "#{SheldonClient.host}/specials/graphs/nodes/#{id}/repair" )
    end

    def repair_connection_url(id)
      Addressable::URI.parse( "#{SheldonClient.host}/specials/graphs/connections/#{id}/repair" )
    end

    def initialize_connections_rules_url
      Addressable::URI.parse( "#{SheldonClient.host}/specials/graphs/connections/all/rules/initialize" )
    end

    def all_nodes_rule_url(rule)
      Addressable::URI.parse( "#{SheldonClient.host}/specials/graphs/nodes/all/rules/#{rule}" )
    end


    def stream_url(user_id, options = {})
      path = "/stream/users/#{user_id.to_i}"
      uri = Addressable::URI.parse( SheldonClient.host + path )
      uri.query_values = stringify_fixnums( options ) unless options.empty?
      uri
    end

    def batch_connections_url
      Addressable::URI.parse( SheldonClient.host + "/connections/batch" )
    end

    def node_containers_url(node, options = {})
      show = options.delete(:show) || :featured_stories
      path = "/nodes/#{node.to_i}/containers/#{show}"
      uri = Addressable::URI.parse( SheldonClient.host + path )
      uri.query_values = stringify_fixnums( options ) unless options.empty?
      uri
    end

    def node_suggestions_url(node, options = {})
      path = "/suggestions/items/#{node.to_i}"
      uri = Addressable::URI.parse( SheldonClient.host + path )
      uri.query_values = stringify_fixnums( options ) unless options.empty?
      uri
    end

    def subscriber_favorites_url(node, options={})
      path = "/traversals/subscriber_favorites/for/#{node.to_i}"
      uri = Addressable::URI.parse( SheldonClient.host + path )
      uri.query_values = stringify_fixnums( options ) unless options.empty?
      uri
    end

    def global_subscriber_favorites_url(options={})
      path = "/traversals/subscriber_favorites"
      uri = Addressable::URI.parse( SheldonClient.host + path )
      uri.query_values = stringify_fixnums( options ) unless options.empty?
      uri
    end

    def questionnaire_url(questionnaire)
      Addressable::URI.parse( "#{SheldonClient.host}/questionnaires/#{questionnaire.to_i}")
    end

    def activity_url(user)
      Addressable::URI.parse( "#{SheldonClient.host}/activities/users/#{user.to_i}")
    end

    private

    def stringify_fixnums(hsh)
      hsh.each do |key, value|
        hsh[key] = value.to_s if value.is_a?(Numeric)
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

    def is_id?( *args )
      args[0].is_a?(Numeric) or (!args[0].to_i.zero?  unless args[0].is_a?(Symbol))
    end
  end
end
