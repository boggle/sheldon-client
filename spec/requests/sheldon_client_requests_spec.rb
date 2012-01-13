require 'spec_helper'

describe SheldonClient do
  def sandbox_id
    269086
  end

  def delete_test_nodes
    results  = SheldonClient.search(sandbox_id: sandbox_id)
    results.each do  |node|
      SheldonClient.delete(node) rescue true
      Elastodon.remove_from_index node.id
    end
  end

  before(:all) do
    WebMock.allow_net_connect!
    SheldonClient.host = ENV['sheldon'] || "http://sheldon.staging.moviepilot.com:2311"
    SheldonClient.elastodon_host = ENV['elastodon'] || 'http://ci-staging01.moviepilot.com:9200'
  end

  after(:all) do
    WebMock.disable_net_connect!
  end

  describe "searching" do
    it "finds a node on sheldon" do
      SheldonClient.search(title: "The Matrix", type: :movie).first.should_not be_nil
    end

    it "finds an user on sheldon given his facebook's username" do
      SheldonClient.search( username: 'Gonzo Gonzales' ).first.should_not be_nil
    end

    it "finds an user on sheldon given his facebook id" do
      SheldonClient.search( facebook_ids: "100002398994863", type: :user ).first.should_not be_nil
    end
  end

  describe 'degree' do
    it 'counts the amount of matrix directors correctly' do
      SheldonClient.node(416).degree(:directings).should eq(2)
    end

    it 'counts amount of subscribers to twilight' do
      SheldonClient.node(41139).subscription_count.should be > 1300
    end
  end

  context "creating, searching and updating nodes" do
    let(:movie_title) do
      "1234-This is a dummy movie"
    end

    before(:all) do
      delete_test_nodes

      @node = SheldonClient.create(:node,
                                   { type: :movie,
                                     payload: { title: movie_title,
                                                sandbox_id: sandbox_id }})
      sleep 30
    end

    it "creates a node in sheldon" do
      @node.should be_a SheldonClient::Node
      @node.type.should eq(:movie)
      @node.payload[:title].should  eq(movie_title)
      @node.payload[:sandbox_id].should eq(sandbox_id)
    end

    it "gets the node from sheldon" do
      sleep 10
      results = SheldonClient.search(title: movie_title, sandbox_id: sandbox_id )
      results.size.should eq(1)
      results.first.should be_a SheldonClient::Node
      results.first.id.should eq(@node.id)
    end

    it "updates the node in sheldon" do
      @node[:production_year] = "1999"
      @node.save.should eq(true)

      node = SheldonClient.node @node.id
      @node.should_not eq(node)
      node.payload[:title].should eq(movie_title)
      node.payload[:sandbox_id].should eq(sandbox_id)
      node.payload[:production_year].should eq("1999")
    end

    it "replaces the resource when calling with update" do
      SheldonClient.update(@node, production_year: "1999").should eq(true)
      node = SheldonClient.node @node.id
      node.payload[:title].should be nil
      node.payload[:sandbox_id].should be nil
      node.payload[:production_year].should eq("1999")
    end

    it "deletes node in sheldon" do
      SheldonClient.delete(@node).should eq(true)
    end
  end

  context "creating and deleting connections between nodes" do
    let(:movie_title) do
      "1234-This is a dummy movie"
    end

    before(:all) do
      delete_test_nodes
      @movie =  SheldonClient.create(:node,
                           { type: :movie,
                             payload: { title: movie_title,
                                        sandbox_id: sandbox_id }})

      @gozno = SheldonClient.search( username: 'Gonzo Gonzales' ).first

      @connection = SheldonClient.create :connection,
                                    { type: :likes,
                                      from: @gozno.id,
                                      to: @movie.id,
                                      payload: { weight: 0.5 }}
    end

    after(:all) do
      SheldonClient.delete(connection: @connection.id) rescue true
      delete_test_nodes
    end

    it "creates a connection between two nodes" do
      @movie.should_not be_nil
      @gozno.should_not be_nil

      @connection.should be_a SheldonClient::Connection

      @connection.from_id.should eq(@gozno.id)
      @connection.to.should eq(@movie)
      @connection.payload[:weight].should eq(0.5)
    end

    it "finds the created connection in sheldon" do
      SheldonClient.connection(@connection.id).should eq(@connection)
      SheldonClient.connection(from: @gozno, to: @movie, type: :likes ).should eq(@connection)
    end

    it "deletes a connection" do
      SheldonClient.delete(connection: @connection.id).should eq(true)

      lambda{ SheldonClient.connection(@connection.id) }.should raise_error SheldonClient::NotFound
      lambda{ SheldonClient.connection(from:@gozno, to: @movie, type: :likes ) }.should raise_error SheldonClient::NotFound
    end
  end

  describe "getting all the ids of the nodes with the given type" do
    it "has several entries for users" do
      SheldonClient.all(:users).count.should be > 100
    end

    it "has more than a thousand of nodes" do
      SheldonClient.all(:nodes).count.should be > 1000
    end
  end

  #FIXME: reactivate when elastodon can handle connections and sheldonclient can reindex stuff
  #describe "reindexing nodes" do
  #  it "should reindex a node" do
  #    gozno = SheldonClient.search( username: 'Gonzo Gonzales' ).first
  #    gozno.should_not be_nil

  #    SheldonClient.reindex(gozno).should eq(true)
  #    SheldonClient.reindex(node: gozno).should eq(true)
  #    SheldonClient.reindex(node: gozno.id).should eq(true)
  #  end

  #  it "should reindex connections" do
  #    connections = SheldonClient.all(:connections)
  #    connections.should_not be_empty

  #    connection = SheldonClient.connection connections.first
  #    connection.should be_a SheldonClient::Connection
  #    SheldonClient.reindex(connection).should eq(true)
  #    SheldonClient.reindex(connection: connection).should eq(true)
  #    SheldonClient.reindex(connection: connection.id).should eq(true)
  #  end
  #end

  describe "statistics" do
    it "has a thousands of movies" do
      statistics = SheldonClient.statistics
      (statistics["nodes"]["movies"]["count"] > 1000 ).should eq(true)
    end
  end
end

