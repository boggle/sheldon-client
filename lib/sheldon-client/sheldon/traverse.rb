class SheldonClient
  class Traverse
    def self.basic_suggestions(start_node)
      SheldonClient::Read.traverse( "suggesters/basic", start_node)
    end

    def self.pagerank(start_node, type)
      SheldonClient::Read.pagerank( "pagerank", start_node, type)
    end
  end
end
