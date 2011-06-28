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

    xit "should find an user on sheldon given his facebook's username" do
      SheldonClient.search( username: 'gonzo gonzales' ).first.should_not be_nil
    end

    xit "should find an user on sheldon given his facebook id" do
      SheldonClient.search( { facebook_ids: "100002398994863" }, type: :user ).first.should_not be_nil
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
end
