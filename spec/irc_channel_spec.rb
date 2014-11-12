require 'spec_helper'

describe IrcChannel do
  before(:each) do
    @irc_connection = double(:irc_connection, :nick => 'Otto', :email => 'otto@example.com')
    @flow_hash = Yajl::Parser.parse(fixture('flows')).first

    @channel = IrcChannel.new(@irc_connection, @flow_hash)
  end

  it "should know how to parse itself from JSON" do
    expect(@channel.flowdock_id).to eq("irc/ottotest")
    expect(@channel.url).to eq("https://api.flowdock.com/flows/irc/ottotest")
    expect(@channel.irc_id).to eq("#irc/ottotest")
    expect(@channel.web_url).to eq("https://www.flowdock.com/app/irc/ottotest")
  end

  it "should parse users data and ignore disabled users" do
    expect(@channel.users.size).to eq(3)
  end

  it "should find users by ID" do
    user = @channel.find_user_by_id(1)
    expect(user.nick).to eq("Otto")
    expect(user.email).to eq("otto@example.com")
  end

  it "should find users by nick, case insensitively" do
    user = @channel.find_user_by_nick('ottoMob')
    expect(user.nick).to eq('Ottomob')
    expect(user.email).to eq('ottomob@example.com')
  end

  it "should return nil when user is not found" do
    expect(@channel.find_user_by_id(1337)).to be_nil
    expect(@channel.find_user_by_nick("BLARGH")).to be_nil
  end

  it "should return nil when argument is nil" do
    expect(@channel.find_user_by_id(nil)).to be_nil
    expect(@channel.find_user_by_nick(nil)).to be_nil
  end

  it "should update attributes" do
    expect(@channel.users.size).to eq(3)
    expect(@channel).to be_open

    @flow_hash["open"] = false
    @flow_hash["users"] << {:id => 99999, :nick => "newuser", :email => "newuser!newuser@example.com"}
    @flow_hash["url"] = "https://api.example.com/flows/org/flow"
    @flow_hash["web_url"] = "https://www.example.com"
    @flow_hash["name"] = "New Flow Name"
    @flow_hash["organization"] = {"name" => "New Organization Name"}

    @channel.update(@flow_hash)
    expect(@channel).not_to be_open
    expect(@channel.users.size).to eq(4)
    expect(@channel.flowdock_id).to eq('org/flow')
    expect(@channel.url).to eq('https://api.example.com/flows/org/flow')
    expect(@channel.web_url).to eq('https://www.example.com')
    expect(@channel.topic).to eq('New Flow Name (New Organization Name)')
  end

  it "should join channel and restart stream if channel becomes open" do
    @flow_hash["open"] = false
    @channel.update(@flow_hash)
    @flow_hash["open"] = true
    expect(@irc_connection).to receive(:restart_flowdock_connection!)
    expect(@irc_connection).to receive(:send_reply).with(/JOIN :#irc\/ottotest/)

    @channel.update(@flow_hash)
  end

  it "should close channel on part" do
    expect(@channel).to be_open
    expect(@irc_connection).to receive(:update_flow)
    @channel.part!
    expect(@channel).not_to be_open
  end

  describe "#build_message" do
    subject {
      @channel.build_message(content: "foo")
    }
    it "sets to parameter" do
      expect(subject[:flow]).to eq(@channel.id)
    end

    it "message data" do
      expect(subject[:content]).to eq("foo")
    end
  end
end
