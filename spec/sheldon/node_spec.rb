require 'spec_helper'

describe SheldonClient::Node do
  include HttpSupport
  include WebMockSupport
  include SheldonClient::UrlHelper

  before(:each) do
    SheldonClient::Status.stub!(:status).and_return( sheldon_status )
    SheldonClient::Schema.stub!(:schema).and_return( sheldon_schema )
  end

  let(:payload)   { { some: 'key' } }
  let(:node_type) { :movie }
  let(:connection_id){ rand(100) }

  describe "Node#(==)" do
    let(:url)     { node_url(1) }
    let(:node_id) { 0 }

    it "should return true when comparing two nodes which are equal" do
      rsp  = response(:node_collection)

      stub_request(:get, url).with(request_data).to_return(response(:node))

      node1 = SheldonClient.node(1)
      node2 = SheldonClient.node(1)
      node1.should eq(node2)
    end
  end

  context "extra_search_data" do
    let(:node){ SheldonClient::Node.new({"id"=>33, "type"=>:movie, "payload"=>{}, "extra_search_data"=>"The godfather"}) }
    it "should set the extra_search_data if passed" do
      node.extra_search_data.should eq("The godfather")
    end

    it "should not return the extra_search_data by default" do
      node.to_hash.symbolize_keys.should_not have_key(:extra_search_data)
    end

    it "should return the extra search data if requested" do
      node.to_hash(include_search_data: true).symbolize_keys[:extra_search_data].should eq("The godfather")
    end
  end

  describe "#update_extra_search_data" do
    let(:movie){ SheldonClient::Node.new({ "id"=>33, "type"=>:movie,  "payload"=>{ title: 'The Godfather' } })  }
    let(:person){ SheldonClient::Node.new({"id"=>34, "type"=>:person, "payload"=>{ name: 'Al Pacino'      } }) }
    let(:bucket){ SheldonClient::Node.new({"id"=>35, "type"=>:bucket, "payload"=>{ name: 'Gangster'       } }) }
    let(:container){ SheldonClient::Node.new({"id"=>36, "type"=>:container, "payload"=> {} }) }


    it "should set the proper extra_search_data if it node is a bucket" do
      bucket.should_receive(:neighbours).with(:related_tos).and_return([container, movie])
      bucket.update_extra_search_data!
      bucket.extra_search_data.should eq("The Godfather")
    end

    it "should set the proper extra_search_data if it node is a movie" do
      movie.should_receive(:neighbours).with(:actings).and_return([person])
      movie.update_extra_search_data!
      movie.extra_search_data.should eq("Al Pacino")
    end

    it "should set the proper extra_search_data if it node is a person" do
      person.should_receive(:neighbours).with(:actings).and_return([movie])
      person.update_extra_search_data!
      person.extra_search_data.should eq("The Godfather")
    end

    it "should put an empty string in extra_search_data if it unhandled type" do
      container.update_extra_search_data!
      container.extra_search_data.should be_blank
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

  context "marking as special" do
    let(:node_id) { 2 }
    let(:url) { node_url(node_id) }
    let(:payload)   { { some: 'key' } }
    let(:node_type) { :movie }

    before(:each) do
      @node = SheldonClient::Node.new(id: node_id, type: node_type, payload: payload)
    end

    it "should add the marker to the payload and add a flag that has a mark" do
      body = payload.update(marked: :true, marks: [:manual_buzz_bucket])
      stub_and_expect_request(:put, url, request_data(body), response(:success)) do
        @node.mark :manual_buzz_bucket
      end
    end

    it "should not add the mark twice" do
      body = payload.update(marked: :true, marks: [:manual_buzz_bucket])
      stub_and_expect_request(:put, url, request_data(body), response(:success)) do
        @node.mark :manual_buzz_bucket
      end

      @node.mark :manual_buzz_bucket
      @node.marks.should eq([:manual_buzz_bucket])
    end

    it "should add the marker to the payload" do
      @node.payload.update(marked: :true, marks: [:manual_buzz_bucket])
      body = payload.update(marked: :true, marks: [:manual_buzz_bucket, :p_buzz_bucket])
      stub_and_expect_request(:put, url, request_data(body), response(:success)) do
        @node.mark :p_buzz_bucket
      end
    end

    it "should allow the deletion of a mark and delete flag marked" do
      @node.payload.update(marked: :true, marks: [:manual_buzz_bucket])
      body = payload.update(marked: nil, marks: nil)
      stub_and_expect_request(:put, url, request_data(body), response(:success)) do
        @node.unmark :manual_buzz_bucket
      end
    end

    it "should allow the deletion of a mark and keep the rest" do
      @node.payload.update(marked: true, marks: [:manual_buzz_bucket, :pontus_buzz])
      body = payload.update(marked: true, marks: [:manual_buzz_bucket])

      stub_and_expect_request(:put, url, request_data(body), response(:success)) do
        @node.unmark :pontus_buzz
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

      it "should export itself as hash" do
        stub_and_expect_request(:get, url, request_data, response(:node)) do
          node = SheldonClient.node(node_id)
          node.to_hash.symbolize_keys.should == {
            id: 4,
            type: :movie,
            payload: {'title' => 'Tonari no Totoro', 'production_year' => 1992}
          }
        end
      end
    end

    context "containers" do
      let(:url){node_containers_url(node) }
      let(:node_type){ "Container" }
      let(:node_id){ 23 }
      let(:payload){ {'title' =>  "Cartman says: 'Justing Bieber should burn in hell'" } }

      it "should fetch recently published containers" do
        stub_and_expect_request(:get, url, request_data, response(:node_collection)) do
            containers = node.containers
            containers.should_not be_empty
            containers.first.id.should eq(23)
        end
      end

      it "should return an empty array if there are no container" do
        stub_and_expect_request(:get, url, request_data, response(:empty_collection)) do
          containers = node.containers
          containers.should be_empty
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

      it "should be available as a class method" do
        url = neighbours_url( node_id, :like )
        stub_and_expect_request(:get, url, request_data, response(:neighbour_collection)) do
            neighbours = SheldonClient::Node.neighbours( node_id, :like )
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
