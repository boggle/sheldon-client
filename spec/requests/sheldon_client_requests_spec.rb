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
    pending
    it "should find a node on sheldon" do
      SheldonClient.search(:movies, title: "The Matrix").first.should_not be_nil
    end

    it "should find an user on sheldon given his facebook's username" do
      SheldonClient.search( :users, username: 'gonzo gonzales' ).first.should_not be_nil
    end

    it "should find an user on sheldon given his facebook id" do
      SheldonClient.search(:users, facebook_ids: "100002398994863").first.should_not be_nil
    end
  end

  describe "creating and searching nodes" do
    let(:movie_title) do
      "1234-This is a dummy movie"
    end

    before(:all) do
      results  = SheldonClient.search(:movies, title: movie_title)
      results.each{ |node| SheldonClient.delete_node(node.id) }

      @node = SheldonClient.create(:node, { type: :movie, payload: { title: movie_title }})
    end

    after(:all) do
      SheldonClient.delete_node(@node.id)
    end

    it "should have created a node in sheldon" do
      @node.should_not be_false
    end

    it "should get the node from sheldon" do
      results = SheldonClient.search(:movies, title: movie_title)
      results.size.should eq(1)

      results.first.should eq(@node)
    end
  end

  describe "creating and deleting connections between nodes" do
  end
end
