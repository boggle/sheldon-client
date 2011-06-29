require 'spec_helper'

describe SheldonClient::Node do
  include HttpSupport
  include WebMockSupport
  include SheldonClient::UrlHelper

  before(:each) do
    SheldonClient::Status.stub!(:status).and_return( sheldon_status )
  end

  let(:payload)   { { some: 'key' } }
  let(:node_type) { :movie }

  describe "Node#(==)" do
    let(:url)     { "http://46.4.114.22:2311/search?mode=exact&some=key" }
    let(:node_id) { 0 }

    it "should return true when comparing two nodes which are equal" do
      rsp  = response(:node_collection)

      stub_request(:get, url).with(request_data).to_return(response(:node_collection))
      node1 = SheldonClient.search some: 'key'
      node2 = SheldonClient.search some: 'key'
      node1.should eq(node2)
    end
  end

  context "creation" do
    let(:url)     { node_url(:movie) }
    let(:node_id) { 0 }

    it "should create a node" do
      stub_and_expect_request(:post, url, request_data(payload), response(:node_created)) do
        SheldonClient.create( :node, type: :movie, payload: payload )
      end
    end

    it "should return the node upon creation" do
      stub_and_expect_request(:post, url, request_data(payload), response(:node_created)) do
        SheldonClient.create( :node, type: :movie, payload: payload ).should be_a(SheldonClient::Node)
      end
    end

    it "should return false if the node could not be created" do
      stub_and_expect_request(:post, url, request_data(payload), response(:bad_request)) do
        SheldonClient.create( :node, type: :movie, payload: payload ).should eq(false)
      end
    end

    it "should raise ArgumentError on unsupported node type" do
      lambda do
        SheldonClient.create( :node, type: :unknown )
      end.should raise_error( ArgumentError )
    end
  end

  context "retrieval" do
    let(:node_id) { 1 }
    let(:url)     { node_url(node_id) }

    it "should return the node" do
      stub_and_expect_request(:get, url, request_data, response(:node)) do
        node = SheldonClient.node( node_id )
        node.should be_a(SheldonClient::Node)
        node.type.should == node_type
        node.id.should   == node_id
      end
    end

    it "should return false on error" do
      stub_and_expect_request(:get, url, request_data, response(:not_found)) do
        SheldonClient.node( node_id ).should be_nil
      end
    end
  end

  context "updating" do
    let(:node_id) { 2 }
    let(:url)     { node_url(node_id) }

    it "should accept a hash as parameter" do
      stub_and_expect_request(:put, url, request_data(payload), response(:node)) do
        SheldonClient.update( { node: node_id }, payload )
      end
    end

    it "should accept node-object as parameter" do
      stub_and_expect_request(:put, url, request_data(payload), response(:node)) do
        SheldonClient.update( SheldonClient::Node.new(id: node_id, type: node_type), payload )
      end
    end

    it "should return false when node not found" do
      stub_and_expect_request(:put, url, request_data(payload), response(:not_found)) do
        SheldonClient.update( SheldonClient::Node.new(id: node_id, type: node_type), payload ).should == false
      end
    end
  end

  context "deletion" do
    let(:node_id) { 3 }
    let(:url)     { node_url(node_id) }

    it "should accept a hash as parameter" do
      stub_and_expect_request(:delete, url, request_data, response(:success)) do
        SheldonClient.delete( node: node_id )
      end
    end

    it "should accept node-object as parameter" do
      stub_and_expect_request(:delete, url, request_data, response(:success)) do
        SheldonClient.delete( SheldonClient::Node.new(id: node_id, type: node_type) )
      end
    end

    it "should return true on succes" do
      stub_and_expect_request(:delete, url, request_data, response(:success)) do
        SheldonClient.delete( SheldonClient::Node.new(id: node_id, type: node_type) ).should == true
      end
    end

    it "should return false on an error" do
      stub_and_expect_request(:delete, url, request_data, response(:not_found)) do
        SheldonClient.delete( SheldonClient::Node.new(id: node_id, type: node_type) ).should eq(false)
      end
    end
  end

  describe "object methods" do
    let(:node_id)         { 4 }
    let(:node)            { SheldonClient::Node.new( id: node_id, type: :user ) }

    context "payload" do
      let(:url)     { node_url(node_id) }
      let(:payload) { { title: 'Tonari no Totoro', production_year: 1992 } }

      it "should access payload elements via []" do
        stub_and_expect_request(:get, url, request_data, response(:node)) do
          SheldonClient.node( node_id )[:title].should == 'Tonari no Totoro'
        end
      end

      it "should set payload elements via []=" do
        stub_and_expect_request(:get, url, request_data, response(:node)) do
          node = SheldonClient.node( node_id )
          node[:title].should == 'Tonari no Totoro'
          node[:title] = 'My Neighbour Totoro'
          stub_and_expect_request(:put, url, request_data(payload.update(title: 'My Neighbour Totoro')), response(:node)) do
            node.save.should == true
          end
        end
      end

      it "should set the payload when using payload=" do
        stub_and_expect_request(:get, url, request_data, response(:node)) do
          node = SheldonClient.node( node_id )
          node[:title].should == 'Tonari no Totoro'
          node.payload = { some: 'key' }
          stub_and_expect_request(:put, url, request_data(some: 'key'), response(:node)) do
            node.save.should == true
          end
        end
      end
    end

    context "connections" do
      let(:from_id)             { node_id }
      let(:to_id)               { node_id + 1 }
      let(:connection_type)     { :like }
      let(:connection_payload)  { { weight: 0.8 } }

      context "fetch" do
        let(:url) { node_connections_url( node, connection_type ) }
        it "should fetch all connections of certain type" do
          stub_and_expect_request(:get, url, request_data, response(:connection_collection)) do
            connections = node.connections( :likes )
            connections.should be_a(Array)
            connections.first.should be_a(SheldonClient::Connection)
            connections.first.from_id.should == from_id
            connections.first.to_id.should   == to_id
          end
        end
      end

      context "create" do
        let(:url) { node_connections_url( from_id, connection_type, to_id ) }

        it "should create an connection (via node object)" do
          stub_and_expect_request(:put, url, request_data(payload), response(:connection_created)) do
            node.likes SheldonClient::Node.new( id: to_id, type: :movie ), payload
          end
        end

        it "should create an connection (via node-id)" do
          stub_and_expect_request(:put, url, request_data(connection_payload), response(:connection_created)) do
            node.likes to_id, connection_payload
          end
        end

        it "should return false if invalid connection target given" do
          stub_and_expect_request(:put, url, request_data, response(:bad_request)) do
            node.likes( to_id, connection_payload ).should == false
          end
        end

        it "should create an connection without a payload" do
          stub_and_expect_request(:put, url, request_data({}), response(:connection_created)) do
            node.likes( to_id ).should be_a( SheldonClient::Connection )
          end
        end

        it "should raise error if a wrong connection type is specified" do
          node.type.should == :user
          lambda {
            node.actors( SheldonClient::Node.new( id: node_id + 1 ), payload )
          }.should raise_error( NoMethodError )
        end
      end
    end

    context "fetch neighbours" do
      # see context connections create for create neighbour specs
      let(:neighbour_id)      { node_id + 2 }
      let(:connection_type)   { :like }
      let(:neighbour_type)    { :genre }
      let(:neighbour_payload) { { name: "Anime" } }


      it "should fetch all neighbours" do
        url = neighbours_url( node_id )
        stub_and_expect_request(:get, url, request_data, response(:neighbour_collection)) do
          neighbours = node.neighbours
          neighbours.should be_a(Array)
          neighbours.first.id.should == neighbour_id
        end
      end

      it "should fetch all neighbours of certain type" do
        url = neighbours_url( node_id, :like )
        stub_and_expect_request(:get, url, request_data, response(:neighbour_collection)) do
            neighbours = node.neighbours( :like )
            neighbours.should be_a(Array)
            neighbours.first.id.should == neighbour_id
          end
      end

      it "should raise an error on invalid neighbour type" do
        lambda{
          node.neighbours( :dummy )
        }.should raise_error( ArgumentError )
      end
    end


    context "reindexing" do
      let(:url)     { node_url(node_id, :reindex) }

      it "should return true when reindexing succeeded" do
        stub_and_expect_request(:put, url, request_data, response(:success)) do
          SheldonClient::Node.new( id: node_id, type: node_type ).reindex.should == true
        end
      end

      it "should return false when reindexing failed" do
        stub_and_expect_request(:put, url, request_data, response(:not_found)) do
          SheldonClient::Node.new( id: node_id, type: node_type ).reindex.should == false
        end
      end
    end
  end
end
