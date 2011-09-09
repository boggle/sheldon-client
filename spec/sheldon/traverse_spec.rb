require 'spec_helper'

describe SheldonClient::Statistics do
  include WebMockSupport
  include HttpSupport

  let(:suggest_url){ traversal_url( 'suggesters/basic', 123 )}
  it "calls the url for basic suggestions" do
    stub_and_expect_request(:get, suggest_url, request_data, response(:statistics)) do
      response = SheldonClient::Traverse.basic_suggestions 123
      response.should be_a Hash
    end
  end

  let(:pagerank_url){ traversal_url( 'pagerank', 123, :containers) }
  it "calls the url for container pagerank" do
    stub_and_expect_request(:get, pagerank_url, request_data, response(:container_pagerank)) do
      response = SheldonClient::Traverse.pagerank 123, :containers
      response.should be_a Array
      response.first[:node].should be_a SheldonClient::Node
    end
  end
end
