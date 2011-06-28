require 'spec_helper'

describe SheldonClient do
  include WebMockSupport
  include HttpSupport

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
    before(:each) do
      @host_url = "http://sheldon.host"
      SheldonClient.host = @host_url
    end

    it "should raise and exception if the given type is not valid" do
      lambda {
        SheldonClient.create :invalid_type, {}
      }.should raise_error(ArgumentError, 'Unknown type')
    end

    it "should make the correct http call  when creating a node" do
      pending
      req_data = request_data({:weight => 1.0 })
      url     = "#{@host_url}/nodes/movies"

      stub_and_expect_request(:post, url, req_data, response(:success)) do
        SheldonClient.create :node, { type: :movie, payload: { weight: 1.0 } }
      end
    end

    it "should make the correct http call when creating a collection" do
      url     = "#{@host_url}/nodes/13/connections/likes/14"
      req_data = request_data({:weight => 1.0 })
      SheldonClient.stub(:connection_types){ [ :likes] }

      stub_and_expect_request(:put, url, req_data, response(:success)) do
        SheldonClient.create :connection,
                             { from: 13,
                               to: 14,
                               type: :likes,
                               payload: { weight: 1.0 }}
      end
    end
  end

#   context "temporary configuration" do
#     before(:each) do
#       SheldonClient.host = 'http://i.am.the.real.sheldon/'
#     end
#
#     it "should switch configuration temporarily" do
#       SheldonClient.host.should == 'http://i.am.the.real.sheldon'
#
#       options = with_options( { :weight => 1.0 }.to_json )
#       result = { :status => 200 }
#       url  = "http://localhost:3000/nodes/movie"
#
#       stub_and_expect_request(:post, url, options, result) do
#         SheldonClient.with_host( 'http://localhost:3000' ) do
#           SheldonClient.create :node, { type: :movie, payload: { weight: 1.0 } }
#         end
#       end
#
#       SheldonClient.host.should == 'http://i.am.the.real.sheldon'
#     end
#   end
#
#   context "building request urls" do
#     it "should create correct url from given options" do
#       SheldonClient.host = 'http://i.am.the.real.sheldon/'
#       SheldonClient.create_edge_url( from: 13, to: 14, type: :foo ).path.should == "/nodes/13/connections/foo/14"
#       SheldonClient.create_edge_url( from: 10, to: 11, type: :bar ).path.should == "/nodes/10/connections/bar/11"
#       SheldonClient.create_node_url( type: :movie ).path.should == "/nodes/movie"
#
#       SheldonClient.build_node_ids_of_type_url( :movies ).path.should == '/nodes/movies/ids'
#       SheldonClient.build_node_ids_of_type_url( :genres ).path.should == '/nodes/genres/ids'
#
#
#       SheldonClient.build_fetch_edge_url( 13, 37, 'genre_taggings' ).path.should == '/nodes/13/connections/genre_taggings/37'
#       SheldonClient.build_fetch_edge_url( 37, 13, 'actings' ).path.should == '/nodes/37/connections/actings/13'
#
#       SheldonClient.build_status_url.path.should == '/status'
#
#       SheldonClient.build_high_score_url( 5 ).path.should             == '/high_scores/users/5'
#       SheldonClient.build_high_score_url( 5, 'tracked').path.should   == '/high_scores/users/5/tracked'
#       SheldonClient.build_high_score_url( 5, 'untracked').path.should == '/high_scores/users/5/untracked'
#
#       SheldonClient.build_recommendation_url( 3 ).request_uri.should == '/recommendations/user/3/containers'
#
#
#     end
#   end
#
  context "delete nodes in sheldon" do
    before(:each) do
      SheldonClient.host = 'http://sheldon.host'
    end

    it "should create a node" do
      stub_request(:delete, "http://other.sheldon.host/nodes/12").
        with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
        to_return(:status => 200)

      SheldonClient.host = 'http://other.sheldon.host'
      SheldonClient.delete(node: 12).should == true
    end

    it "should return false when deleting non existance nodes" do
      stub_request(:delete, "http://other.sheldon.host/nodes/122").
        with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
        to_return(:status => 404)

      SheldonClient.host = 'http://other.sheldon.host'
      SheldonClient.delete(node: 122).should == false
    end
  end
#
#   context "create log file" do
#     it "should write a slow-log file" do
#       SheldonClient.log = true
#       SheldonClient.should_receive(:log_sheldon_request)
#       stub_request( :get, SheldonClient.host + '/nodes/13/connections/actings/15').
#         with( :headers => {'Accept' => 'application/json', 'Content-Type' => 'application/json'}).
#         to_return( :status  => 200, :body => { 'id' => 45, 'type' => 'actings', 'from' => '13', 'to' => '15', 'payload' => { 'weight' => '0.5' }}.to_json )
#       result = SheldonClient.edge?(13, 15, 'actings')
#       SheldonClient.log = false
#     end
#   end
#
#   context "delete connections in sheldon" do
#     before(:each) do
#       SheldonClient.host = 'http://sheldon.host'
#     end
#
#     it "should create a node" do
#       stub_request(:delete, "http://other.sheldon.host/connections/12").
#         with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
#         to_return(:status => 200)
#
#       SheldonClient.host = 'http://other.sheldon.host'
#       SheldonClient.delete_edge(12).should == true
#     end
#
#     it "should return false when deleting non existance nodes" do
#       stub_request(:delete, "http://other.sheldon.host/connections/122").
#         with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
#         to_return(:status => 404)
#
#       SheldonClient.host = 'http://other.sheldon.host'
#       SheldonClient.delete_edge(122).should == false
#     end
#   end
#
#   context "creating" do
#     context "edges" do
#       it "should create an request to create an edge" do
#         options = with_options( { :weight => 1.0 }.to_json )
#         result  = {:status => 200}
#         url     = "http://sheldon.host/nodes/13/connections/movies_genres/14"
#
#         stub_and_expect_request(:put, url, options, result) do
#           SheldonClient.create :edge, { from: 13, to: 14, type: :movies_genres, payload: { weight: 1.0 }}
#         end
#       end
#
#       it "should create edges from node objects" do
#         options = with_options( { :weight => 0.4 }.to_json )
#         result  = {:status => 200}
#         url     = "http://sheldon.host/nodes/123/connections/movies_genres/321"
#
#         stub_and_expect_request(:put, url, options, result) do
#           node1 = SheldonClient::Node.new({'id' => 123, 'type' => 'Movie'})
#           node2 = SheldonClient::Node.new({'id' => 321, 'type' => 'Genre'})
#           SheldonClient.create :edge, { from: node1,
#                                         to: node2,
#                                         type: :movies_genres,
#                                         payload: { weight: 0.4 }}
#         end
#       end
#     end
#   end
#
#
  context "searching for nodes" do
    before(:all){ SheldonClient.host = "http://sheldon.host" }

    let(:payload)   { {}  }

    it "should search for movies" do
      url = "http://sheldon.host/search/nodes/movies?mode=fulltext&production_year=1999&title=Matrix"

      node_type = :movie
      node_id   = 123
      agent = { 'User-Agent' => 'Ruby' }
      response = response(:node_collection, node_id: node_id, node_type: node_type)

      stub_and_expect_request(:get, url, request_data(nil, agent), response ) do
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
#
#   context "node payloads" do
#     it "should return the payload of a given node" do
#       stub_request(:get, "http://sheldon.host/nodes/2001").
#         with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
#         to_return(:status => 200, :body => { "type" => "Movie", "id" => "123", "payload" => { "title" => "MyTitle" } }.to_json )
#
#       result = SheldonClient.node( 2001 )
#       result.should be_a SheldonClient::Node
#       result.id.should == "123"
#       result.payload.should == { "title" => "MyTitle" }
#     end
#   end
#
#   context "updating nodes" do
#     it "should update the the year of a given node" do
#       stub_request(:get, "http://sheldon.host/nodes/500").
#         with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
#         to_return(:status => 200, :body => { :id => 500, :type => "Movie", :payload => { :year => 2000 } }.to_json )
#       stub_request(:put, "http://sheldon.host/nodes/500").
#         with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'},
#              :body    => { :year => 2000 }.to_json).to_return(:status => 200)
#       SheldonClient.update_node( 500, { year: 2000 } ).should == true
#     end
#   end
#
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
