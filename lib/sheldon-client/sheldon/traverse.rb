class SheldonClient
  class Traverse
    def self.basic_suggestions(start_node)
      SheldonClient::Read.traverse( "suggesters/basic", start_node)
    end
  end
end
