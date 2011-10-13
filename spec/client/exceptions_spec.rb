require 'spec_helper'

describe SheldonClient::HTTP::Exceptions do
  before(:all) do
    SheldonClient::HTTP::Exceptions.extend SheldonClient::HTTP::Exceptions
  end

  let(:response){ double(:response, message: "bad request", body: "failure" )}

  it "raises a BadRequest exception" do
    response.stub(:code){ "400" }
    lambda{
      SheldonClient::HTTP::Exceptions.raise_exception(response)
    }.should  raise_error SheldonClient::BadRequest
  end

  it "raises a NotFound exception" do
    response.stub(:code){ "404" }
    lambda{
      SheldonClient::HTTP::Exceptions.raise_exception(response)
    }.should raise_error SheldonClient::NotFound
  end

  it "raises Conflict exception" do
    response.stub(:code){ "409" }
    lambda{
      SheldonClient::HTTP::Exceptions.raise_exception(response)
    }.should raise_error SheldonClient::Conflict
  end

  it "raises Internal Server Error exception" do
    response.stub(:code){ "500" }
    lambda{
      SheldonClient::HTTP::Exceptions.raise_exception(response)
    }.should raise_error SheldonClient::InternalServerError
  end

  it "raises Service Unavaiable exception" do
    response.stub(:code){ "503" }
    lambda{
      SheldonClient::HTTP::Exceptions.raise_exception(response)
    }.should raise_error SheldonClient::ServiceUnavaiable
  end

  it "raises an standar error exception if response code not handled" do
    response.stub(:code){ "501" }
    lambda{
      SheldonClient::HTTP::Exceptions.raise_exception(response)
    }.should raise_error StandardError
  end
end
