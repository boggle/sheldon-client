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
      SheldonClient.search( { facebook_ids: "100002398994863" }, type: :persons ).first.should_not be_nil
    end
  end

  describe "creating and searching nodes" do
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

    after(:all) do
      SheldonClient.delete(@node)
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

      results.first.should == @node
    end
  end
end
