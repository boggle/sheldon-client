require 'spec_helper'

describe SheldonClient::Schema do
  include HttpSupport
  include WebMockSupport

  context "getting schema information from sheldon" do
    before(:each) do
      stub_request(:get, "#{SheldonClient.host}/schema").
        with( :headers => {'Accept' =>'application/json', 'Content-Type'=> 'application/json'}).
        to_return(:status => 200, :body => sheldon_schema.to_json)
    end

    it "should fetch all the current node and edge types supported by sheldon" do
      SheldonClient.node_types.should == [ :movies, :persons ]
      SheldonClient.connection_types.should == [ :likes, :actors, :g_tags ]
    end

    it "should extract all valid outgoing connection types for a node" do
      SheldonClient::Schema.valid_connections_from( :movie ).should == [ :actors, :g_tags ]
      SheldonClient::Schema.valid_connections_from( :users ).should == [ :likes ]
    end

    it "should extract all valid incoming connection types for a node" do
      SheldonClient::Schema.valid_connections_to( :movie ).should == [ :likes ]
      SheldonClient::Schema.valid_connections_to( :users ).should == [ ]
    end

    it "should know valid source and target node types for specific edges" do
      SheldonClient.schema['connections']['likes']['sources'].should == [ 'users' ]
      SheldonClient.schema['connections']['likes']['targets'].should == [ 'movies', 'persons' ]
    end
  end

end
