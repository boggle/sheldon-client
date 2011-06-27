require 'benchmark'
require 'logger'

class SheldonClient
  module HTTP
    def send_request( method, uri, body = nil )
      result = nil
      time = Benchmark.measure do
        result = send_request!( method, uri, body )
      end
      log_sheldon_request( method, uri, time, body ) if SheldonClient.log?
      log_sheldon_response( result ) if SheldonClient.log?
      result
    end

    def send_request!( method, uri, body = nil )
      Net::HTTP.start( uri.host, uri.port ) do |http|
        http.read_timeout = 3600
        req = build_request( method, uri, body )
        default_headers(req)
        result = http.request(req)
      end
    end

    def build_request( method, uri, body = nil )
      request = Object.module_eval("Net::HTTP::#{method.capitalize}").new( uri.request_uri )
      request.body = body.to_json if body
      request
    end

    def default_headers( request )
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
    end

    def create_edge_url(options)
      from = options[:from].is_a?(Node) ? options[:from].id : options[:from].to_i
      to   = options[:to].is_a?(Node) ? options[:to].id : options[:to].to_i
      Addressable::URI.parse( self.host + "/nodes/#{from}/connections/#{options[:type]}/#{to}" )
    end

    def create_node_url(options)
      Addressable::URI.parse( self.host + "/nodes/#{options[:type]}" )
    end

    def build_node_url( id )
       Addressable::URI.parse( self.host + "/nodes/" + id.to_s )
    end

    def build_edge_url( id )
       Addressable::URI.parse( self.host + "/connections/" + id.to_s )
    end

    def build_neighbour_url( node_id, type )
      uri = Addressable::URI.parse( self.host + "/nodes/" + node_id.to_s + "/neighbours/" + type.to_s )
    end

    def build_node_ids_of_type_url( type )
       Addressable::URI.parse( self.host + "/nodes/" + type.to_s + '/ids' )
    end

    def build_reindex_node_url( id )
      Addressable::URI.parse( self.host + '/nodes/' + id.to_s + '/reindex' )
    end

    def build_reindex_edge_url( id )
      Addressable::URI.parse( self.host + '/connections/' + id.to_s + '/reindex' )
    end

    def build_fetch_edge_url( from, to, type )
      Addressable::URI.parse( self.host + '/nodes/' + from.to_s + '/connections/' + type.to_s + '/' + to.to_s )
    end

    def build_status_url
      Addressable::URI.parse( self.host + '/status' )
    end

    def build_high_score_url( node_id, type = nil)
      tracked = type ? '/' + type.to_s : ''
      Addressable::URI.parse( self.host + '/high_scores/users/' + node_id.to_s + tracked )
    end

    def build_recommendation_url( node_id)
      Addressable::URI.parse( self.host + '/recommendations/user/' + node_id.to_s + '/containers')
    end

    def log_sheldon_request( method, url, time, body = '' )
      write_log_line( "#{time.real} #{method.upcase} #{url}" )
      write_log_line( "curl -v -X #{method.upcase} #{url}" + ((!body or body.empty?) ? "" : " -d '#{body.to_json}'") )
    end
    
    def log_sheldon_response( result )
      write_log_line( "Sheldon-Response <#{result.code}>: #{result.body}" )
    end
    
    def write_log_line( log_line )
      log_line = "[#{Time.now}] #{log_line}"
      log_file ? get_logger.info(log_line) : puts(log_line)
    end

    def get_logger
      @logger ||= Logger.new(log_file)
    end
  end
end
