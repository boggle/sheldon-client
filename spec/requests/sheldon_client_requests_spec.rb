require 'spec_helper'

describe SheldonClient do
  before(:all) do
    WebMock.allow_net_connect!
  end

  after(:all) do
    WebMock.disable_net_connect!
  end

  before(:each) do
    SheldonClient.host = "http://46.4.114.22:2311"
  end

  describe "configuration" do
    it "should talk to the right sheldon server" do
      SheldonClient.host.should == "http://46.4.114.22:2311"
    end
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
    end

    after(:all){ SheldonClient.delete(@movie) }

    before(:each) do
      @movie = SheldonClient.search(sandbox_id: sandbox_id).first
      @gozno = SheldonClient.search( username: 'gonzo gonzales' ).first
    end

    it "should connect the two given nodes" do
      @movie.should_not be_nil
      @gozno.should_not be_nil

      connection = SheldonClient.create :connection,
                                    { type: :likes,
                                      from: @gozno.id,
                                      to: @movie.id,
                                      payload: { weight: 0.5 }}

      connection.should be_a SheldonClient::Connection

      connection.from.should eq(@gozno)
      connection.to.should eq(@movie)
      connection.payload[:weight].should eq(0.5)

      @movie.connections(:likes).include?(connection).should eq(true)
      @gozno.connections(:likes).include?(connection).should eq(true)

      SheldonClient.delete(connection: connection.id).should eq(true)

      @movie.connections(:likes).include?(connection).should eq(false)
      @gozno.connections(:likes).include?(connection).should eq(false)
    end
  end
end


