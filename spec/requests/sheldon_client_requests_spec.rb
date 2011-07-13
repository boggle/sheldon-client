require 'spec_helper'

describe SheldonClient do
  before(:all) do
    WebMock.allow_net_connect!
  end

  after(:all) do
    WebMock.disable_net_connect!
  end

  describe "searching" do
    it "should find a node on sheldon" do
      SheldonClient.search({title: "The Matrix"}, type: :movie).first.should_not be_nil
    end

    it "should find an user on sheldon given his facebook's username" do
      SheldonClient.search( username: 'gonzo gonzales' ).first.should_not be_nil
    end

    it "should find an user on sheldon given his facebook id" do
      SheldonClient.search( { facebook_ids: "100002398994863" }, type: :user ).first.should_not be_nil
    end
  end

  context "creating, searching and updating nodes" do
    let(:movie_title) do
      "1234-This is a dummy movie"
    end

    let(:sandbox_id){ 269086 }

    before(:all) do
      results  = SheldonClient.search(sandbox_id: sandbox_id)
      results.each{ |node| SheldonClient.delete(node) }

      @node = SheldonClient.create(:node,
                                   { type: :movie,
                                     payload: { title: movie_title,
                                                sandbox_id: sandbox_id }})
    end

    it "should have created a node in sheldon" do
      @node.should be_a SheldonClient::Node
      @node.type.should eq(:movie)
      @node.payload[:title].should  eq(movie_title)
      @node.payload[:sandbox_id].should eq(sandbox_id)
    end

    it "should get the node from sheldon" do
      results = SheldonClient.search(title: movie_title, sandbox_id: sandbox_id )
      results.size.should eq(1)
      results.first.should be_a SheldonClient::Node

      results.first.should eq(@node)
    end

    it "should update the node in sheldon" do
      SheldonClient.update({ node: @node.id }, production_year: "1999").should eq(true)
      results = SheldonClient.search(title: movie_title, sandbox_id: sandbox_id )
      node = results.first
      @node.should_not eq(node)
      node.payload[:title].should  eq(movie_title)
      node.payload[:sandbox_id].should eq(sandbox_id)
      node.payload[:production_year].should eq("1999")
    end

    it "should delete node in sheldon" do
      SheldonClient.delete(@node).should eq(true)
    end
  end

  context "creating and deleting connections between nodes" do
    let(:movie_title) do
      "1234-This is a dummy movie"
    end

    let(:sandbox_id){ 269086 }

    before(:all) do
      results  = SheldonClient.search(sandbox_id: sandbox_id)
      results.each{ |node| SheldonClient.delete(node) }

     @movie =  SheldonClient.create(:node,
                           { type: :movie,
                             payload: { title: movie_title,
                                        sandbox_id: sandbox_id }})

      @movie = SheldonClient.search(sandbox_id: sandbox_id).first
      @gozno = SheldonClient.search( username: 'gonzo gonzales' ).first

      @connection = SheldonClient.create :connection,
                                    { type: :likes,
                                      from: @gozno.id,
                                      to: @movie.id,
                                      payload: { weight: 0.5 }}
    end

    after(:all) do
      SheldonClient.delete(@movie)
      SheldonClient.delete(connection: @connection.id)
    end

    it "should create a connection between two nodes" do
      @movie.should_not be_nil
      @gozno.should_not be_nil

      @connection.should be_a SheldonClient::Connection

      @connection.from.should eq(@gozno)
      @connection.to.should eq(@movie)
      @connection.payload[:weight].should eq(0.5)
    end

    it "should find the created connection in sheldon" do
      SheldonClient.connection(@connection.id).should eq(@connection)
      SheldonClient.connection(from: @gozno, to: @movie, type: :likes ).should eq(@connection)
    end

    it "should delete a connection" do
      SheldonClient.delete(connection: @connection.id).should eq(true)

      SheldonClient.connection(@connection.id).should eq(false)
      SheldonClient.connection(from:@gozno, to: @movie, type: :likes ).should eq(false)
    end
  end

  describe "getting all the ids of the nodes with the given type" do
    it "should have several entries for users" do
      users_ids = SheldonClient.all(:users)
      (users_ids.count > 100).should eq(true)
    end

    it "should have more than a thousand of nodes" do
      nodes_ids = SheldonClient.all(:nodes)
      (nodes_ids.count > 1000).should eq(true)
    end

    it "should have more than a hundred connections" do
      nodes_ids = SheldonClient.all(:nodes)
      (nodes_ids.count > 100).should eq(true)
    end
  end

  describe "reindexing nodes" do
    it "should reindex a node" do
      gozno = SheldonClient.search( username: 'gonzo gonzales' ).first

      SheldonClient.reindex(gozno).should eq(true)
      SheldonClient.reindex(node: gozno).should eq(true)
      SheldonClient.reindex(node: gozno.id).should eq(true)
    end

    it "should reindex connections" do
      connections = SheldonClient.all(:connections)
      connections.should_not be_empty

      connection = SheldonClient.connection connections.first
      connection.should be_a SheldonClient::Connection
      SheldonClient.reindex(connection).should eq(true)
      SheldonClient.reindex(connection: connection).should eq(true)
      SheldonClient.reindex(connection: connection.id).should eq(true)
    end
  end

  describe "statistics" do
    it "should have a thousands of movies" do
      statistics = SheldonClient.statistics
      (statistics["nodes"]["movies"]["count"] > 1000 ).should eq(true)
    end
  end
end

