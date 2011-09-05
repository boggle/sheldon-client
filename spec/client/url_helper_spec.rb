require 'spec_helper'

describe SheldonClient::UrlHelper do
  include SheldonClient::UrlHelper

  context "neighbours_url" do
    it "should generate all neighbour url" do
      uri = neighbours_url( 1 )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/neighbours"
    end

    it "should generate neighbour url for type" do
      uri = neighbours_url( 1, :like )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/neighbours/likes"
    end
  end

  context "node_url" do
    it "should create an url with type" do
      uri = node_url(:movie)
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/movies"
    end

    it "should create an url with type and id" do
      uri = node_url(:movie, 1)
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/movies/1"
    end

    it "should create an url with id" do
      uri = node_url(1)
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1"
    end

    it "should create an url with id as string" do
      uri = node_url('1')
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1"
    end

    it "should create the reindex url" do
      uri = node_url(1, :reindex)
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/reindex"
    end
  end

  context "status_url" do
    it "should create sheldons status url" do
      uri = status_url
      uri.should be_a( Addressable::URI )
      uri.path.should == "/status"
    end
  end

  context "schema_url" do
    it "should create sheldons schema url" do
      uri = schema_url
      uri.should be_a( Addressable::URI )
      uri.path.should == "/schema"
    end
  end

  context "node_connections_url" do
    it "should create new connection url" do
      uri = node_connections_url( 1, :like, 2 )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/connections/likes/2"
    end

    it "should create fetch connections url" do
      uri = node_connections_url( 1, :like )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/connections/likes"
    end
  end

  context "node_type_ids" do
    let(:type){ :movie }
    it "should return the correct url to node/:type/ids" do
      uri = node_type_ids_url(type)

      uri.should be_a Addressable::URI
      uri.path.should eq("/nodes/movies/ids")
    end
  end

  context "reindex_url" do
    let(:connection){ SheldonClient::Connection.new(id:23) }
    let(:node){ SheldonClient::Node.new(id:23) }

    let(:node_reindex_url){ "/nodes/#{node.id}/reindex" }
    let(:connection_reindex_url){ "/connections/#{connection.id}/reindex"  }

    it "should return the correct url for node reindex" do
      reindex_url(node: node.id).path.should eq(node_reindex_url)
      reindex_url(node: node).path.should eq(node_reindex_url)
    end

    it "should return the correct url for connecton reindex" do
      reindex_url(connection: connection.id).path.should eq(connection_reindex_url)

      reindex_url(connection: connection).path.should eq(connection_reindex_url)
    end

    it "should return the correct url if we pass a node object" do
      reindex_url(node).path.should eq(node_reindex_url)
    end

    it "should return the correct url if we pass a connection object " do
      reindex_url(connection).path.should eq(connection_reindex_url)
    end
  end

  context "statistics_url" do
    it "should create sheldons statistics url" do
      uri = statistics_url
      uri.should be_a( Addressable::URI )
      uri.path.should == "/statistics"
    end
  end

  context "all_ids_url" do
    it "should create the url for all the nodes" do
      uri = all_ids_url(:nodes)
      uri.should be_a( Addressable::URI )
      uri.path.should == "/ids/nodes"
    end

    it "should create the url for all the connections" do
      uri = all_ids_url(:connections)
      uri.should be_a( Addressable::URI )
      uri.path.should == "/ids/connections"
    end
  end

  context "user_stream_url" do
    let(:user_id){2}
    let(:user){ SheldonClient::Node.new(id: user_id, type: :user) }

    it "should create the user stream url when given user" do
      uri  = stream_url user
      uri.should be_a( Addressable::URI )
      uri.path.should eq("/stream/users/#{user_id}")
    end

    it "should create the user stream url when given the user id" do
      uri  = stream_url "2"
      uri.should be_a( Addressable::URI )
      uri.path.should eq("/stream/users/#{user_id}")
    end

    it "should add page and per_page to the user stream" do
      uri  = stream_url "2", page: 1, per_page: 5
      uri.should be_a( Addressable::URI )
      uri.path.should eq("/stream/users/#{user_id}")
      uri.query_values.should eq({"page" => "1", "per_page" => "5"})
    end
  end
end
