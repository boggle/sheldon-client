module SheldonClient
  class Status < Crud
    #
    # Get the sheldon status json hash including some basic
    # information with current edge and node statistics.
    #
    # === Example
    #
    # SheldonClient.status
    # => { ... }
    def self.status
      @status ||= get_sheldon_status
    end

    private

    def self.get_sheldon_status
      response = send_request( :get, status_url )
      response.code == '200' ? status = JSON.parse( response.body ) : nil
    end
  end
end
