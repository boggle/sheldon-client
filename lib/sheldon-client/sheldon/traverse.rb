module SheldonClient
  class Traverse
    def self.basic_suggestions(start_node, options = {})
      SheldonClient::Read.traverse( "suggesters/basic", start_node, options)
    end

    def self.pagerank(start_node, type, options = {})
      SheldonClient::Read.pagerank( "pagerank", start_node, type, options)
    end
  end
end
