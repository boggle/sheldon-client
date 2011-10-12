require 'benchmark'
require 'logger'
require 'net/http'
require_relative 'exceptions'

class SheldonClient
  module HTTP
    include Exceptions

    private

    def send_request( method, uri, body = nil )
      result = nil
      time = Benchmark.measure do
        result = send_request!( method, uri, body )
      end

      if SheldonClient.log?
        log_sheldon_request( method, uri, time, body )
        log_sheldon_response( result )
      end
      raise_exception(result)
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

    def parse_sheldon_response( json_body )
      data_hash = JSON.parse( json_body )
      if is_edge?( data_hash )
        SheldonClient::Connection.new data_hash
      else
        SheldonClient::Node.new data_hash
      end
    end

    def is_edge?( data )
       data['from'] and data['to']
    end


    def build_request( method, uri, body = nil )
      request = Object.module_eval("Net::HTTP::#{method.capitalize}").new( uri.request_uri )
      request.body = body.to_json if body
      request
    end

    def default_headers( request )
      request['Content-Type'] = 'application/json'
      request['Accept']       = 'application/json'
    end

    def log_sheldon_response( result )
      SheldonClient.write_log_line( "Sheldon-Response <#{result.code}>: #{result.body}" )
    end

    def log_sheldon_request( method, url, time, body = '' )
      SheldonClient.write_log_line( "#{time.real} #{method.upcase} #{url}" )
      SheldonClient.write_log_line( "curl -v -X #{method.upcase} '#{url}" + ((!body or body.empty?) ? "'" : "' -d '#{body.to_json}'") )
    end
  end
end
