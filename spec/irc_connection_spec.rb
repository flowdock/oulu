require 'spec_helper'

def flow_data(id)
  {
    "id" => id,
    "users" => [{
      "id" => 1,
      "nick" => "test",
      "email" => "test@example.com"
    }]
  }
end

describe IrcConnection do
  before(:each) do
    @connection = IrcConnection.new(nil)
  end

  it "should ignore messages sent by same connection" do
    @connection.should_not_receive(:send_reply)

    message = {:flow => "example:main", :app => "chat", :event => "message", :content => "testing message echo ignoring"}
    @connection.instance_variable_set(:@outgoing_messages, [message])
    @connection.channels["example/main"] = IrcChannel.new(@connection, flow_data("example/main"))
    @connection.send(:receive_flowdock_event, MultiJson.encode(message.merge(:user => 1)))

  end

  it "should not ignore if message has different origin" do
    @connection.should_receive(:send_reply)

    message = {:flow => "example:foo", :app => "chat", :event => "message", :content => "testing message echo ignoring"}
    @connection.instance_variable_set(:@outgoing_messages, [message.merge(:flow => "example:main")])
    @connection.channels["example/main"] = IrcChannel.new(@connection, flow_data("example/main"))
    @connection.channels["example/foo"] = IrcChannel.new(@connection, flow_data("example/foo"))
    @connection.send(:receive_flowdock_event, MultiJson.encode(message.merge(:user => 1)))
  end

  it "should send PING messages" do
    @connection.should_receive(:last_ping_sent=).with(/FLOWDOCK-/)
    @connection.should_receive(:send_reply).with(/PING/)
    @connection.ping!
  end

  describe "receiving data" do
    it "should parse a single line of text" do
      @connection.should_receive(:parse_line).once.with("NICK test")
      @connection.receive_data("NICK test\r\n")
    end

    it "should parse multiple lines of text" do
      counter = 0
      @connection.should_receive(:parse_line).twice.with do |data|
        ["NICK mutru", "USER mutru mutru localhost :Otto Hilska"].include?(data).should be_true
      end

      @connection.receive_data("NICK mutru\r\nUSER mutru mutru localhost :Otto Hilska\r\n")
    end
  end

  describe "finding users and channels" do
    before(:each) do
      @connection.channels = {'irc/ottotest' => example_irc_channel(@connection)}
    end

    it "should find channel with its Flowdock ID" do
      @connection.find_channel('irc/ottotest').irc_id.should == "#irc/ottotest"
    end

    it "should find channel with its IRC ID" do
      @connection.find_channel('#irc/ottotest').flowdock_id.should == 'irc/ottotest'
    end

    it "should return nil when a channel is not found" do
      @connection.find_channel('DOES_NOT_EXIST').should be_nil
    end

    it "should return when querying channel with name nil" do
      @connection.find_channel(nil).should be_nil
    end

    it "should find users by ID" do
      user = @connection.find_user_by_id(1)
      user.should be_a(User)
      user.id.should == 1
      user.nick.should == 'Otto'
    end

    it "should return nil when users are not found by ID" do
      @connection.find_user_by_id(2).should be_nil
    end

    it "should return nil when querying user by nil ID" do
      @connection.find_user_by_id(nil).should be_nil
    end

    it "should find users by nick, case insensitively" do
      user = @connection.find_user_by_nick('otTo')
      user.should be_a(User)
      user.id.should == 1
      user.nick.should == 'Otto'
    end

    it "should return nil when users are not found by nick" do
      @connection.find_user_by_nick('WHATEVER').should be_nil
    end

    it "should return nil when querying user by nil nick" do
      @connection.find_user_by_nick(nil).should be_nil
    end

    it "should resolve nick conflicts" do
      @connection.send(:process_current_user, 1)
      @connection.send(:resolve_nick_conflicts!)
      user = @connection.find_user_by_nick('OTTOMOB2')
      user.should be_a(User)
      user.id.should == 50002
      user.name.should == 'Fake ottomob'
    end
  end

  describe "posting messages" do
    it "should create an HTTP request" do
      EventMachine.run {
        @connection.email = "foo@example.com"
        @connection.password = "supersecret"

        stub_request(:post, "https://api.flowdock.com/v1/flows/irc/ottotest/messages").
          with(:body => /Hello world!/,
           :headers => {'Authorization'=>['foo@example.com', 'supersecret'], 'Content-Type'=>'application/json'}).
          to_return(:status => 200, :body => "", :headers => {})

        @connection.post_chat_message('irc/ottotest', 'Hello world!')
        EventMachine.stop
      }
    end
  end

  it "should have a send_reply method for posting data to the client, adding newlines" do
    @connection.should_receive(:send_data).with("foo\r\n")
    @connection.send_reply("foo")
  end

  it "should reset FlowdockConnection when setting an away message" do
    old_state = @connection.authenticated? 
    @connection.instance_variable_set(:@authenticated, true) 
    FlowdockConnection.any_instance.should_receive(:start!)
    @connection.set_away("gone")
    @connection.away_message.should == "gone"
    @connection.instance_variable_set(:@authenticated, old_state) 
  end

  it "should not reset FlowdockConnection again when changing from away message to another" do
    old_state = @connection.authenticated? 
    @connection.instance_variable_set(:@authenticated, true) 
    FlowdockConnection.any_instance.should_receive(:start!).once
    @connection.set_away("gone")
    @connection.away_message.should == "gone"
    @connection.set_away("gone more") # start! not called anymore
    @connection.away_message.should == "gone more"
    @connection.instance_variable_set(:@authenticated, old_state) 
  end

  it "should not try to reset FlowdockConnection when setting an away message and not authenticated" do
    old_state = @connection.authenticated? 
    @connection.instance_variable_set(:@authenticated, false) 
    FlowdockConnection.any_instance.should_not_receive(:start!)
    @connection.set_away("gone")
    @connection.away_message.should == "gone"
    @connection.instance_variable_set(:@authenticated, old_state) 
  end

end
