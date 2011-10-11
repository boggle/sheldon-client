require 'spec_helper'

describe SheldonClient do
  include WebMockSupport
  include HttpSupport
  include SheldonClient::UrlHelper

  let(:host_url){ "http://sheldon.host" }

  context "configuration" do
    it "should have a predefined host" do
      SheldonClient.host.should == 'http://sheldon.staging.moviepilot.com:2311'
    end

    it "should return to the configured host" do
      SheldonClient.host = 'http://i.am.the.real.sheldon/'
      SheldonClient.host.should == 'http://i.am.the.real.sheldon'
    end

    it "should return the default log level (false)" do
      SheldonClient.log?.should == false
      SheldonClient.log = true
      SheldonClient.log?.should == true
      SheldonClient.log = false
    end
  end

  describe "SheldonClient.create" do
    let(:node_id){ 123 }

    before(:each) do
      SheldonClient.host = host_url
      SheldonClient.stub(:node_types){ [ :movies, :persons ] }
      SheldonClient.stub(:connection_types){ [ :likes, :actors, :g_tags ] }
    end

    it "should raise and exception if the given type is not valid" do
      lambda {
        SheldonClient.create :invalid_type, {}
      }.should raise_error(ArgumentError, 'Unknown type')
    end

    it "should make the correct http call  when creating a node" do
      url     = "#{host_url}/nodes/movies"
      payload = {"title" => 'The Matrix' }
      rsp      = response(:node_created, node_type: :movie, payload: payload)
      req_data = request_data(payload)

      stub_and_expect_request(:post, url, req_data, rsp) do
        result = SheldonClient.create :node, { type: :movie, payload: payload }
        result.should be_a SheldonClient::Node
        result.id.should eq(123)
        result.type.should eq(:movie)
        result.payload.should eq(payload)
      end
    end

    it "should make the correct http call when creating a connection" do
      url     = node_connections_url(13, :likes, to: 14)
      payload = {"weight" => 1.0 }
      req_data = request_data(payload)
      rsp = response(:connection_created,
                     connection_type: :likes,
                     from_id: 13,
                     to_id: 14,
                     payload: payload,
                     connection_id: 15)

      stub_and_expect_request(:put, url, req_data, rsp ) do
        connection = SheldonClient.create :connection,
                             { from: 13,
                               to: 14,
                               type: :likes,
                               payload: payload}

        connection.should be_a SheldonClient::Connection
        connection.payload.should eq(payload)
        connection.id.should eq(15)
      end
    end

    it "should return false if the response code is different of 200" do
      url     = "#{host_url}/nodes/movies"
      payload = {"title" => 'The Matrix' }
      rsp      = response(:bad_request)
      req_data = request_data(payload)

      stub_and_expect_request(:post, url, req_data, rsp) do
        result = SheldonClient.create :node, { type: :movie, payload: payload }
        result.should be(false)
      end
    end
  end

  context "updating a connection" do
    let(:payload){ { weight: '0.5' } }
    let(:url){ node_connections_url( 2, :likes, to: 3)}

    it "should accept a hash as parameter" do
      stub_and_expect_request(:put, url, request_data(payload), response(:success)) do
        SheldonClient.update( { connection: {from: 2, to: 3, type: :likes} }, payload )
      end
    end

    it "should accept connection-object as parameter" do
      connection = SheldonClient::Connection.new(from: 2, to: 3, type: :like)
      stub_and_expect_request(:put, url, request_data(payload), response(:success)) do
        SheldonClient.update(connection, payload )
      end
    end

    it "should return false when node not found" do
      connection = SheldonClient::Connection.new(from: 2, to: 3, type: :like)
      stub_and_expect_request(:put, url, request_data(payload), response(:not_found)) do
        SheldonClient.update( connection, payload ).should eq(false)
      end
    end
  end


  context "temporary configuration" do
    let(:node_id)   { 1                }
    let(:node_type) { :movie           }
    let(:payload)   { {:weight => 1.0} }

    before(:each) do
      SheldonClient.host = 'http://i.am.the.real.sheldon/'
      SheldonClient.stub(:node_types){ [ :movies, :persons ] }
      SheldonClient.stub(:connection_types){ [ :likes, :actors, :g_tags ] }
    end


    it "should switch configuration temporarily" do
      SheldonClient.host.should == 'http://i.am.the.real.sheldon'
      req_data = request_data(payload)
      rsp      = response(:node_created)
      url  = "http://localhost:3000/nodes/movies"

      stub_and_expect_request(:post, url, req_data, response(:node_created)) do
        SheldonClient.with_host( 'http://localhost:3000' ) do
          response =SheldonClient.create :node, { type: node_type, payload: payload }
          response.should be_a(SheldonClient::Node)
        end
      end
      SheldonClient.host.should == 'http://i.am.the.real.sheldon'
    end
  end

  context "delete connections in sheldon" do
    before(:each) do
      SheldonClient.host = host_url
    end

    it "should delete a connection" do
      url = "#{host_url}/connections/12"
      stub_and_expect_request(:delete, url, request_data, response(:success)) do
        SheldonClient.delete(connection: 12).should eq(true)
      end
    end

    it "should delete a connection when given a connection object" do
      url = "#{host_url}/connections/12"
      stub_and_expect_request(:delete, url, request_data, response(:success)) do
        connection = SheldonClient::Connection.new(id:12)
        SheldonClient.delete(connection).should eq(true)
      end
    end

    it "should delete a connection given to, from and type" do
      url = "#{host_url}/connections/12"
      result = response(:connection,
                        connection_type: :like,
                        connection_id: 12,
                        from_id: 13,
                        to_id: 15,
                        payload: {})
      stub_and_expect_request(:delete, url, request_data, response(:success)) do
        connection_url = node_connections_url(13, :like, to: 15)

        stub_and_expect_request(:get, connection_url, request_data, result ) do
          SheldonClient.delete(connection: {from:13, to:15, type: :like}).should eq(true)
        end
      end
    end

    it "should return false when deleting non existance nodes" do
      url = "#{host_url}/connections/122"
      stub_and_expect_request(:delete, url, request_data, response(:not_found)) do
        SheldonClient.delete(connection: 122).should eq(false)
      end
    end

    it "should delete all connection of a given type from a node" do
      url = node_connections_url(15, :like)
      stub_and_expect_request(:delete, url, request_data, response(:success)) do
        SheldonClient.delete(connection: { from:15, type: :likes }).should eq(true)
      end
    end
  end

  context "searching for nodes" do
    let(:node_type) {:movie}
    let(:node_id)   {0}
    let(:payload)   { {} }

    it "should pass search parameters to elastodon" do
      Elastodon.should_receive(:emulate_sheldon_search).with('query', {}).and_return( response(:node_collection)[:body] )

      result = SheldonClient.search('query', {}).should eq( SheldonClient::Search.parse_search_result( response(:node_collection)[:body] ) )
    end
  end

  context "getting connections" do
    let(:connection_type){ :like }
    let(:from_id){ 13 }
    let(:to_id){ 15 }
    let(:connection_payload){ { 'weight' => '0.5' } }
    let(:url){ node_connections_url(from_id, :like, to: to_id ) }
    let(:connection_id){ 45 }

    before(:each) do
      SheldonClient.host = host_url
    end

    it "should get the outgoing connections, given the from, type and direction" do
      url = node_connections_url( from_id, connection_type, direction: :outgoing )
      stub_and_expect_request(:get, url, request_data, response(:connection_collection)) do
        connections = SheldonClient.connection(from: from_id, type: :likes, direction: :outgoing )
        connections.should be_a(Array)
        connections.first.should be_a(SheldonClient::Connection)
        connections.first.from_id.should == from_id
        connections.first.to_id.should   == to_id
      end
    end

    it "should get the incoming connections, given the from, type and direction" do
      url = node_connections_url( from_id, connection_type, direction: :incoming )
      stub_and_expect_request(:get, url, request_data, response(:connection_collection)) do
        connections = SheldonClient.connection(from: from_id, type: :likes, direction: :incoming )
        connections.should be_a(Array)
        connections.first.should be_a(SheldonClient::Connection)
        connections.first.from_id.should == from_id
        connections.first.to_id.should   == to_id
      end
    end

    it "should get a connection given the the ids of from, to and the type " do
      stub_and_expect_request(:get, url, request_data, response(:connection) ) do
        connection = SheldonClient.connection(from:13, to:15, type: :like)
        connection.should be_a SheldonClient::Connection
        connection.id.should eq(45)
        connection.from_id.should eq(from_id)
        connection.to_id.should eq(to_id)
        connection.type.should eq(:like)
        connection.payload['weight'].should eq(connection_payload['weight'])
      end
    end

    it "should get a connection given the nodes from, to and the type" do
      node_from = SheldonClient::Node.new(id:13)
      node_to = SheldonClient::Node.new(id:15)

      stub_and_expect_request(:get, url, request_data, response(:connection) ) do
        connection = SheldonClient.connection(from:node_from, to:node_to, type: :like)
        connection.should be_a SheldonClient::Connection
        connection.id.should eq(connection_id)
        connection.from_id.should eq(from_id)
        connection.to_id.should eq(to_id)
        connection.type.should eq(:like)
        connection.payload['weight'].should eq(connection_payload['weight'])
      end
    end

    it "should get a connection given its id" do
      url = connnections_url(connection_id)
      stub_and_expect_request(:get, url, request_data, response(:connection)) do
        connection = SheldonClient.connection(connection_id)
        connection.should be_a SheldonClient::Connection
        connection.id.should eq(45)
        connection.from_id.should eq(from_id)
        connection.to_id.should eq(to_id)
        connection.type.should eq(:like)
        connection.payload['weight'].should eq(connection_payload['weight'])
      end
    end

    it "should result false if the connection doesn't exist" do
      stub_and_expect_request(:get, url, request_data, response(:not_found)) do
        connection = SheldonClient.connection(from:from_id, to:to_id, type: :like)
        connection.should eq(false)
      end
    end
  end

  context "fetching all ids of a given type" do
    let(:type){ :users }
    let(:url){ node_type_ids_url(type) }
    let (:node_url){ all_ids_url(:nodes) }
    let (:connections_url){ all_ids_url(:connections) }

    it "should fetch all the ids of a certain type" do
      result  = {status: 200, body: [12, 34].to_json }
      stub_and_expect_request(:get, url, request_data, result) do
        SheldonClient.all(type).should eq([12, 34])
      end
    end

    it "should not return nil values all the ids of a certain type" do
      result  = {status: 200, body: [12, 34, nil, nil].to_json }
      stub_and_expect_request(:get, url, request_data, result) do
        SheldonClient.all(type).should eq([12, 34])
      end
    end

    it "should fetch nodes ids" do
      result  = {status: 200, body: [1, 2, 3].to_json }
      stub_and_expect_request(:get, node_url, request_data, result) do
        SheldonClient.all(:nodes).should eq([1,2,3])
      end
    end

    it "should fetch connections ids" do
      result  = { status: 200, body: [1, 2, 3].to_json }
      stub_and_expect_request(:get, connections_url, request_data, result) do
        SheldonClient.all(:connections).should eq([1,2,3])
      end
    end
  end

  context "reindexing nodes and connection" do
    let(:connection){ SheldonClient::Connection.new(id:12)}
    let(:connection_url){ reindex_url(connection: connection.id) }
    let(:node){ SheldonClient::Node.new(id:2)}
    let(:node_url){ reindex_url(node: node.id) }

    it "should make the correct http call when reindexing a connection its id" do
      stub_and_expect_request(:put, connection_url, request_data, response(:success)) do
        SheldonClient.reindex(connection: connection.id).should eq(true)
      end
    end

    it "should make the correct http call when reindexing a connection passed in a hash" do
      stub_and_expect_request(:put, connection_url, request_data, response(:success)) do
        SheldonClient.reindex(connection: connection).should eq(true)
      end
    end

    it "should make the correct http call when reindexing a connection " do
      stub_and_expect_request(:put, connection_url, request_data, response(:success)) do
        SheldonClient.reindex(connection).should eq(true)
      end
    end

    it "shoudld make the correct http call when reindexing a node by its id" do
      stub_and_expect_request(:put, node_url , request_data, response(:success)) do
        SheldonClient.reindex(node: node.id).should eq(true)
      end
    end

    it "shoudld make the correct http call when reindexing a node passed in a hash" do
      stub_and_expect_request(:put, node_url , request_data, response(:success)) do
        SheldonClient.reindex(node: node).should eq(true)
      end
    end

    it "shoudld make the correct http call when reindexing a node" do
      stub_and_expect_request(:put, node_url , request_data, response(:success)) do
        SheldonClient.reindex(node).should eq(true)
      end
    end

    it "shoudld return false if response is not 200" do
      stub_and_expect_request(:put, node_url , request_data, response(:not_found)) do
        SheldonClient.reindex(node).should eq(false)
      end
    end

    it "shoudld return false if response is not 200" do
      stub_and_expect_request(:put, connection_url , request_data, response(:not_found)) do
        SheldonClient.reindex(connection ).should eq(false)
      end
    end
  end

  describe "SheldonClient.special_nodes" do
    let(:payload)   { { some: 'key', marked: true } }
    let(:node_type) { :movie }

    before(:each) do
      @nodes = [ SheldonClient::Node.new(id: 1,
                                         type: node_type,
                                         payload: payload.update( marks: [:pontus])),
                 SheldonClient::Node.new(id: 2,
                                         type: node_type,
                                         payload: payload.update(marks: [:adolfo,
                                                                         :pontus]))]
      SheldonClient.stub!(:search).with(marked: true){ @nodes }
    end

    it "should return all the categories and the nodes in it" do
      result = SheldonClient.marked_nodes
      result.keys.should eq([:pontus, :adolfo])
      result.should eq({ pontus: @nodes,
                         adolfo: [@nodes[1]] })
    end
  end

  describe "SheldonClient.stream" do
    let(:user){ SheldonClient::Node.new(id: 2, type: :user) }
    let(:payload){ { published_at: "2011-07-06T12:44:03+02:00",
                     updated_at: "Mon Jul 18 11:16:08 +0200 2011",
                     created_at: "Fri Jul 08 20:23:13 +0200 2011",
                     edward_id: 820,
                     title: "'Dexter's Lab', 'Clone Wars'...'Hotel Transylvania'" }}
    let(:node_id){ 22 }
    let(:node_type){ 'Container' }


    it "should make the correct http call when called without options" do
      url = "#{SheldonClient.host}/stream/users/2"
      stub_and_expect_request(:get, url, request_data, response(:node_collection)) do
        SheldonClient.stream(user).should_not be_empty
      end
    end

    it "should make the correct http call with options" do
      url = "#{SheldonClient.host}/stream/users/2?page=1&per_page=5"
      stub_and_expect_request(:get, url, request_data, response(:node_collection)) do
        SheldonClient.stream(user, page: 1, per_page: 5).should_not be_empty
      end
    end
  end

  describe "batch operations" do
    let(:payload){{ weight: 1 }}

    it "should batch the creation of connections" do
      url = batch_connections_url
      connections = [ { from: 13, to: 14, type: :likes, payload: payload },
                      { from: 13, to: 16, type: :genre_taggings, payload: payload },
                      { from: 13, to: 20, type: :actings, payload: payload } ]

      stub_and_expect_request(:put, url, request_data(connections), response(:success)) do
        SheldonClient.batch do |batch|
          batch.create :connection, connections[0]
          batch.create :connection, connections[1]
          batch.create :connection, connections[2]
        end
      end
    end

    it "should batch the update of connections" do
      url = batch_connections_url
      connections = [ { from: 13, to: 14, type: :likes, payload: payload },
                      { from: 13, to: 16, type: :genre_taggings, payload: payload }]


      stub_and_expect_request(:put, url, request_data(connections), response(:success)) do
        SheldonClient.batch do |batch|
          batch.update :connection, connections[0]
          batch.update :connection, connections[1]
        end
      end
    end

    it "should raise and error if an unknown type is given" do
      connections = [ { from: 13, to: 14, type: :likes, payload: payload } ]
      lambda{
        SheldonClient.batch do |batch|
          batch.create :car, connections[0]
        end
      }.should raise_error(ArgumentError)

    end
  end

  describe "questionnaire" do
    let(:questionnaire_id){ 22 }
    let(:url){ questionnaire_url questionnaire_id }
    let(:question){ "Will Cthulhu appear in south park again?" }
    let(:payload){ { "question" => question } }
    let(:answerers){ { "255412" => [{ "facebook_ids" => ["2"], "id" => 2 }] } }
    let(:replies){
      {
        "255412" => {
                      "payload" => { "type" => "replies", "text" => "jhghjjgj"},
                      "type" => "Reply",
                      "id" => 2525
                    }
      }
    }

    it "should get the questionnaire with the given id" do
      stub_and_expect_request(:get, url, request_data, response(:questionnaire)) do
        questionnaire = SheldonClient.questionnaire(questionnaire_id)
        questionnaire.should_not be_false

        questionnaire.should be_a(SheldonClient::Questionnaire)

        questionnaire["question"].should eq(question)
        questionnaire.replies.should have_key("255412")
        questionnaire.answerers.should have_key("255412")
      end
    end
  end
end
