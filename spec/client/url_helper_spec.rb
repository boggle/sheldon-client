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

    it "should generate the neigbour url for incoming connectiong if specified" do
      uri = neighbours_url( 1, :like, :incoming )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/neighbours/likes/incoming"
    end
    it "should generate the neigbour url for outgoing connectiong if specified" do
      uri = neighbours_url( 1, :like, :outgoing )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/neighbours/likes/outgoing"
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
      uri = node_connections_url( 1, :like, to: 2 )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/connections/likes/2"
    end

    it "should create fetch connections url" do
      uri = node_connections_url( 1, :like )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/connections/likes"
    end

    it "should create an outgoing fetch connection url" do
      uri = node_connections_url( 1, :like, direction: :outgoing )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/connections/likes/outgoing"
    end

    it "should create an incoming fetch connection url" do
      uri = node_connections_url( 1, :like, direction: :incoming )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/connections/likes/incoming"
    end

    it "should ignore direction if to is given" do
      uri = node_connections_url( 1, :like, to: 2, direction: :incoming )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/connections/likes/2"
    end

    it "should default to all types of connections" do
      uri = node_connections_url( 1, :all )
      uri.should be_a( Addressable::URI )
      uri.path.should == "/nodes/1/connections/all"
    end
  end

  context 'node_degree_url' do
    it 'should call node_connections_url and append /degree' do
      connections_uri = Addressable::URI.parse('http://some.server/blub')
      self.should_receive(:node_connections_url).with(1, 2, 3).and_return(connections_uri)

      uri = node_degree_url(1, 2, 3)
      uri.should be_a( Addressable::URI )
      uri.path.should == "/blub/degree"
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

  context "node container url" do
    let(:node_id){ 23 }
    let(:node){ SheldonClient::Node.new(id: node_id, type: :container) }

    it "should return the containers url for the given node" do
      uri = node_containers_url node
      uri.should be_a( Addressable::URI )
      uri.path.should eq("/nodes/#{node_id}/containers/featured_stories")
    end

    it "should accept params and use them in the query" do
      uri = node_containers_url node, per_page: 10, page: 13, show: "all_stories"
      uri.should be_a( Addressable::URI )
      uri.path.should eq("/nodes/#{node_id}/containers/all_stories")

      uri.query_values.should eq({"page" => "13", "per_page" => "10"})
    end
  end

  context "node suggestions url" do
    let(:node_id){ 34 }
    let(:node){ SheldonClient::Node.new(id: node_id, type: :container) }

    it "builds the sheldon correct url" do
      uri = node_suggestions_url node
      uri.should be_a( Addressable::URI )
      uri.path.should eq("/suggestions/items/#{node_id}")
    end

    it "accpets params and use them in the query" do
      uri = node_suggestions_url node, per_page: 10, page: 13
      uri.should be_a( Addressable::URI )
      uri.path.should eq("/suggestions/items/#{node_id}")
      uri.query_values.should eq({"page" => "13", "per_page" => "10"})
    end

  end

  context "questionnaire url" do
    let(:questionnaire){ double('questionnaire') }
    let(:questionnaire_id){ 22 }

    it "should generate the questionnaire url" do
      questionnaire.stub(:to_i).and_return(questionnaire_id)
      uri = questionnaire_url questionnaire
      uri.should be_a( Addressable::URI )
      uri.path.should eq("/questionnaires/#{questionnaire_id}")
    end
  end
end
