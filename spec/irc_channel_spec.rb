require 'spec_helper'

describe IrcChannel do
  before(:each) do
    @irc_connection = mock(:irc_connection)
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

  it "should update user list" do
    @channel.users.size.should == 3
    @flow_hash["users"] << {:id => 99999, :nick => "newuser", :email => "newuser!newuser@example.com"}
    @channel.update(@flow_hash)
    @channel.users.size.should == 4
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
