require 'spec_helper'

describe SheldonClient do
  include WebMockSupport
  include HttpSupport

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
      url     = "#{host_url}/nodes/13/connections/likes/14"
      payload = {"weight" => 1.0 }

      req_data = request_data(payload)
      rsp = response(:connection_created,
                     connection_type: :likes,
                     from_id: 13,
                     to_id: 14,
                     payload: payload)

      stub_and_expect_request(:put, url, req_data, rsp ) do
        result = SheldonClient.create :connection,
                             { from: 13,
                               to: 14,
                               type: :likes,
                               payload: payload}

        result.should be_a SheldonClient::Connection
        result.payload.should eq(payload)
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

  context "delete nodes in sheldon" do
    before(:each) do
      SheldonClient.host = host_url
    end

    it "should delete and generate the correct http call to delete node" do
      url = "#{host_url}/nodes/12"
      stub_and_expect_request(:delete, url, request_data, response(:success)) do
        SheldonClient.delete(node: 12).should == true
      end
    end

    it "should return false when deleting non existance nodes" do
      url = "#{host_url}/nodes/122"
      stub_and_expect_request(:delete, url, request_data, response(:not_found)) do
        SheldonClient.delete(node: 122).should eq(false)
      end
    end
  end

  context "delete connections in sheldon" do
    before(:each) do
      SheldonClient.host = host_url
    end

    it "should delete a connection" do
      url = "#{host_url}/connections/12"

      stub_and_expect_request(:delete, url, request_data, response(:success)) do
        SheldonClient.delete(connection: 12).should == true
      end
    end

    it "should return false when deleting non existance nodes" do
      url = "#{host_url}/connections/122"

      stub_and_expect_request(:delete, url, request_data, response(:not_found)) do
        SheldonClient.delete(connection: 122).should eq(false)
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

#   context "getting all the ids of a node type" do
#     it "should fetch all the movie ids" do
#       stub_request(:get, "http://sheldon.host/nodes/movies/ids" ).
#         with(:headers => {'Accept' => 'application/json', 'Content-Type'=>'application/json'}).
#         to_return(:status => 200, :body => [1,2,3,4,5].to_json )
#       result = SheldonClient.get_node_ids_of_type( :movies )
#       result.should == [1,2,3,4,5]
#     end
#   end
#
#   context "reindexing nodes and edges" do
#
#     it "should send a reindex request to an edge" do
#       stub_request( :put, 'http://sheldon.host/connections/43/reindex').
#         with( :headers => { 'Accept'=>'application/json', 'Content-Type' => 'application/json', 'User-Agent'=>'Ruby'} ).
#         with( :headers => { 'Accept'=>'application/json', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
#         to_return( :status => 200, :headers => {},:body => { 'id' => 43, 'type' => 'actings', 'from' => '13', 'to' => '14', 'payload' => { 'weight' => '0.5'}}.to_json )
#       result = SheldonClient.reindex_edge 43
#       result.should == true
#
#     end
#   end
#
#   context "fetching edges" do
#     it "should get one edge between two nodes of a certain edge type" do
#       stub_request( :get, 'http://sheldon.host/nodes/13/connections/actings/15').
#         with( :headers => {'Accept' => 'application/json', 'Content-Type' => 'application/json'}).
#         to_return( :status  => 200, :body => { 'id' => 45, 'type' => 'actings', 'from' => '13', 'to' => '15', 'payload' => { 'weight' => '0.5' }}.to_json )
#       result = SheldonClient.edge?(13, 15, 'actings')
#       result.id.should == 45
#       result.from.should == '13'
#       result.to.should == '15'
#       result.type.should == 'actings'
#       result.payload['weight'].should == '0.5'
#     end
#
#     it "should get a non-existing node between two nodes" do
#       stub_request( :get, 'http://sheldon.host/nodes/13/connections/genre_taggings/15').
#         with( :headers => {'Accept' => 'application/json', 'Content-Type' => 'application/json'}).
#         to_return( :status  => 404, :body => '' )
#       result = SheldonClient.edge?( 13, 15, 'genre_taggings' )
#       result.should == nil
#
#     end
#
#     it "should get a edge by its id" do
#       stub_request( :get, 'http://sheldon.host/connections/3').
#         with( :headers => {'Accept' => 'application/json', 'Content-Type' => 'application/json'}).
#         to_return( :status => 200, :body => { id:  123, from: "8", to: "58001", type: "Acting", payload: { weight: "0.5"}}.to_json )
#       result = SheldonClient.edge 3
#       result.payload.should == { 'weight' => "0.5"}
#       result.id.to_s.should == '123'
#       result.from.to_s.should == '8'
#       result.to.to_s.should == '58001'
#       result.type.to_s.should == 'Acting'
#     end
#   end
#
#   context "fetching nodes based on facebook id regardless node type" do
#     it "should do one successful search" do
#       stub_request(:get, "http://sheldon.host/search?facebook_ids=123456").
#         with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
#         to_return(:status => 200, :body => [{ "type" => "users", "id" => "123", 'payload'=> {'facebook_ids' =>'123456' }}].to_json, :headers => {})
#
#       result = SheldonClient.facebook_item( '123456' ).first
#       result.type.should == 'users'
#       result.payload['facebook_ids'].should == '123456'
#     end
#   end
#
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
