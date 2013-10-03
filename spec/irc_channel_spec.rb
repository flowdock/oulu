require 'spec_helper'

describe IrcChannel do
  before(:each) do
    @irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@example.com')
    @flow_hash = Yajl::Parser.parse(fixture('flows')).first

    @channel = IrcChannel.new(@irc_connection, @flow_hash)
  end

  it "should know how to parse itself from JSON" do
    @channel.flowdock_id.should == "irc/ottotest"
    @channel.url.should == "https://api.flowdock.com/flows/irc/ottotest"
    @channel.irc_id.should == "#irc/ottotest"
    @channel.web_url.should == "https://www.flowdock.com/app/irc/ottotest"
  end

  it "should parse users data and ignore disabled users" do
    @channel.users.size.should == 3
  end

  it "should find users by ID" do
    user = @channel.find_user_by_id(1)
    user.nick.should == "Otto"
    user.email.should == "otto@example.com"
  end

  it "should find users by nick, case insensitively" do
    user = @channel.find_user_by_nick('ottoMob')
    user.nick.should == 'Ottomob'
    user.email.should == 'ottomob@example.com'
  end

  it "should return nil when user is not found" do
    @channel.find_user_by_id(1337).should be_nil
    @channel.find_user_by_nick("BLARGH").should be_nil
  end

  it "should return nil when argument is nil" do
    @channel.find_user_by_id(nil).should be_nil
    @channel.find_user_by_nick(nil).should be_nil
  end

  it "should update attributes" do
    @channel.users.size.should == 3
    @channel.open?.should be_true

    @flow_hash["open"] = false
    @flow_hash["users"] << {:id => 99999, :nick => "newuser", :email => "newuser!newuser@example.com"}
    @flow_hash["url"] = "https://api.example.com/flows/org/flow"
    @flow_hash["web_url"] = "https://www.example.com"
    @flow_hash["name"] = "New Flow Name"
    @flow_hash["organization"] = {"name" => "New Organization Name"}

    @channel.update(@flow_hash)
    @channel.open?.should be_false
    @channel.users.size.should == 4
    @channel.flowdock_id.should == 'org/flow'
    @channel.url.should == 'https://api.example.com/flows/org/flow'
    @channel.web_url.should == 'https://www.example.com'
    @channel.topic.should == 'New Flow Name (New Organization Name)'
  end

  it "should join channel and restart stream if channel becomes open" do
    @flow_hash["open"] = false
    @channel.update(@flow_hash)
    @flow_hash["open"] = true
    @irc_connection.should_receive(:restart_flowdock_connection!)
    @irc_connection.should_receive(:send_reply).with(/JOIN :#irc\/ottotest/)

    @channel.update(@flow_hash)
  end

  it "should close channel on part" do
    @channel.open?.should be_true
    @irc_connection.should_receive(:update_flow)
    @channel.part!
    @channel.open?.should be_false
  end

  describe "#build_message" do
    subject {
      @channel.build_message(content: "foo")
    }
    it "sets to parameter" do
      subject[:flow].should == @channel.id
    end

    it "message data" do
      subject[:content].should == "foo"
    end
  end
end
