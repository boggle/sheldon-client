require 'spec_helper'

describe SheldonClient::Statistics do
  include WebMockSupport
  include HttpSupport

  let(:url){ traversal_url( 'suggesters/basic', 123 )}
  it "should call the url for statistics" do
    stub_and_expect_request(:get, url, request_data, response(:statistics)) do
      response = SheldonClient::Traverse.basic_suggestions 123
      response.should be_a Hash
    end
  end
end
