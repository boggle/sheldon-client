require 'spec_helper'

describe SheldonClient::Statistics do
  include WebMockSupport
  include HttpSupport
  include SheldonClient::UrlHelper

  let(:url){ statistics_url }
  it "should call the url for statistics" do
    stub_and_expect_request(:get, url, request_data, response(:statistics)) do
      response = SheldonClient.statistics
      response.should be_a Hash
    end
  end
end
