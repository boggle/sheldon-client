module SheldonClient
  class Error               < StandardError; end
  class BadRequest          < Error; end
  class Conflict            < Error; end
  class InternalServerError < Error; end
  class NotFound            < Error; end
  class ServiceUnavaiable   < Error; end

  module HTTP
    module Exceptions
      def raise_exception(response)
        case response.code.to_i
        when 400
          raise BadRequest, get_message(response)
        when 404
          raise NotFound, get_message(response)
        when 409
          raise Conflict, get_message(response)
        when 500
          raise InternalServerError, get_message(response)
        when 503
          raise ServiceUnavaiable, get_message(response)
        else
          raise StandardError, get_message(response)
        end
      end

      def get_message(response)
        "#{response.code}: #{response.message}: #{response.body}"
      end
    end
  end
end
