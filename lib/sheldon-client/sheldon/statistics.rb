module SheldonClient
  class Statistics < Crud
    def self.statistics
      @statistics || get_sheldon_statistics
    end

    private

    def self.get_sheldon_statistics
      response = send_request( :get, statistics_url )
      response.code == '200' ? schema = JSON.parse( response.body ) : nil
    end
  end
end
