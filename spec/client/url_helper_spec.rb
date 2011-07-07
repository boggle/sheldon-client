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

    it "should create the reindex url" do
      uri = node_url(1, :reindex)
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/reindex"
    end
  end

  context "search_url" do
    it "should generate global search url" do
      uri = search_url( 'query' )
      uri.should be_a( Addressable::URI )
      uri.request_uri.should == "/search?mode=exact&q=query"
    end

    it "should generate typed search url" do
      uri = search_url( 'query', type: :movie )
      uri.should be_a( Addressable::URI )
      uri.request_uri.should == "/search/nodes/movies?mode=exact&q=query"
    end

    it "should generate untyped attribute search url" do
      uri = search_url( { title: 'query' } )
      uri.should be_a( Addressable::URI )
      uri.request_uri.should == "/search?mode=exact&title=query"
    end

    it "should generate typed attribute search url" do
      uri = search_url( { title: 'query'}, type: :movie )
      uri.should be_a( Addressable::URI )
      uri.request_uri.should == "/search/nodes/movies?mode=exact&title=query"
    end

    it "should generate exact untyped search url" do
      uri = search_url( { title: 'query' }, mode: :fulltext )
      uri.should be_a( Addressable::URI )
      uri.request_uri.should == "/search?mode=fulltext&title=query"
    end

    it "should generate search url even if the value of a key is a Fixnum" do
      uri = search_url( { id: 1 }, mode: :fulltext )
      uri.should be_a( Addressable::URI )
      uri.request_uri.should == "/search?id=1&mode=fulltext"
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

  context "user high_scores" do
    it "shoudl return the correct url given an user" do
      uri = user_high_scores_url(13)

      uri.should be_a Addressable::URI
      uri.path.should eq("/high_scores/users/13")
    end

    it "should return attach the type to the url if given" do
      uri = user_high_scores_url(13, :tracked)

      uri.should be_a Addressable::URI
      uri.path.should eq("/high_scores/users/13/tracked")

      uri = user_high_scores_url(13, :untracked)

      uri.should be_a Addressable::URI
      uri.path.should eq("/high_scores/users/13/untracked")
    end

    it "shoudl raise an error if an unknown type is given" do
      lambda{
        user_high_scores_url(123, :foo)
      }.should raise_error( ArgumentError )
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
end
