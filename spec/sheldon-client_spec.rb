require 'spec_helper'

describe SheldonClient do
  include WebMockSupport
  include HttpSupport
  include SheldonClient::UrlHelper

  let(:host_url){ "http://sheldon.host" }

  context "configuration" do
    it "should have a predefined host" do
      SheldonClient.host.should == 'http://46.4.114.22:2311'
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
      url     = node_connections_url(13, :likes, 14)
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
    before(:all){ SheldonClient.host = "http://sheldon.host" }

    let(:payload)   { {}  }

    it "should search for movies" do
      url = "http://sheldon.host/search/nodes/movies?mode=fulltext&production_year=1999&title=Matrix"

      node_type = :movie
      node_id   = 123
      response = response(:node_collection, node_id: node_id, node_type: node_type)

      stub_and_expect_request(:get, url, request_data, response ) do
        result = SheldonClient.search( {title: 'Matrix', production_year: '1999'}, type: :movies, mode: :fulltext)
        result.first.should be_a SheldonClient::Node
        result.first.id.should eq(123)
        result.first.type.should eq(:movie)
      end
    end

    it "should convert given query parameters to strings" do
      node_id = 1
      node_type = :genre

      url = "http://sheldon.host/search/nodes/genres?id=#{node_id}&mode=exact"

      response = response(:node_collection, node_id: node_id, node_type: node_type)

      stub_and_expect_request(:get, url, request_data, response ) do
        result = SheldonClient.search({id: 1}, type: node_type)
      end
    end

    it "should search for genres" do
      url = "http://sheldon.host/search/nodes/genres?mode=exact&name=Action"

      stub_and_expect_request(:get, url, request_data, response(:node_collection, node_type: :genre, node_id: 321 )) do
        result = SheldonClient.search({name: 'Action'}, type: :genre)
        result.first.should be_a SheldonClient::Node
        result.first.id.should eq(321)
        result.first.type.should eq(:genre)
      end
    end

    it "should return an empty array on no-content responses" do
      url = "http://sheldon.host/search/nodes/genres?mode=exact&name=Action"

      stub_and_expect_request(:get, url, request_data, response(:empty_collection)) do
        SheldonClient.search({name: 'Action'}, type: :genre ).should eq([])
      end
    end
  end

  context "getting connections" do
    let(:connection_type){ :like }
    let(:from_id){ 13 }
    let(:to_id){ 15 }
    let(:connection_payload){ { 'weight' => '0.5' } }
    let(:url){ node_connections_url(from_id, :like, to_id) }
    let(:connection_id){ 45 }

    before(:each) do
      SheldonClient.host = host_url
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

#
#     def sheldon_status_json
#       { "schema" => { "nodes"       => { "movies"  => { "properties" => [ "name" => [ 'exact' ] ],
#                                                         "count"      => 4  },
#                                          "persons" => { "properties" => [],
#                                                         "count"      => 6  }},
#                       "connections" => { "likes"  => { "properties" => [],
#                                                        "sources"    => [ 'users' ],
#                                                        "targets"    => [ 'movies', 'persons' ],
#                                                        "count"      => 3  }}}
#       }.to_json
#     end
#   end
#
#
#   context "fetching recommendations" do
#     it "should fetch all the recommendations for a user from sheldon" do
#       stub_request( :get, "http://sheldon.host/recommendations/user/3/containers").
#         with( :headers => {'Accept' =>'application/json', 'Content-Type'=> 'application/json'}).
#         to_return( :status=> 200, :body => [ { id: "50292929", type: "Movie", payload: { title: "Matrix", production_year: 1999, has_container: "true" }}].to_json )
#       recommendations = SheldonClient.get_recommendations 3
#       recommendations.should == [ { 'id' => "50292929", 'type' => "Movie", 'payload' => { 'title' => "Matrix", 'production_year' => 1999, 'has_container' => "true" }}]
#     end
#   end
end
