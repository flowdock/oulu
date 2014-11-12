require 'spec_helper'

def flow_data(id, open=true)
  {
    "id" => SecureRandom.urlsafe_base64,
    "url" => "https://api.example.com/flows/#{id}",
    "open" => open,
    "organization" => {
      "name" => "Example"
    },
    "users" => [{
      "id" => 1,
      "nick" => "test",
      "email" => "test@example.com",
      "name" => "Tester"
    }]
  }
end

describe IrcConnection do
  before(:each) do
    @connection = IrcConnection.new(nil)
  end

  it "should ignore messages sent by same connection" do
    flow = flow_data("example/main")
    expect(@connection).not_to receive(:send_reply)

    message = {:flow => flow["id"], :app => "chat", :event => "message", :content => "testing message echo ignoring"}
    @connection.instance_variable_set(:@outgoing_messages, [message])
    @connection.channels["example/main"] = IrcChannel.new(@connection, flow)
    @connection.send(:receive_flowdock_event, MultiJson.dump(message.merge(:user => 1)))
  end

  it "should ignore messages to closed channels" do
    flow = flow_data("example/main", false)
    expect(@connection).not_to receive(:send_reply)

    message = {:flow => flow["id"], :app => "chat", :event => "message", :content => "testing message echo ignoring"}
    @connection.instance_variable_set(:@outgoing_messages, [message])
    @connection.channels["example/main"] = IrcChannel.new(@connection, flow)
    @connection.send(:receive_flowdock_event, MultiJson.dump(message.merge(:user => 1)))
  end

  it "should not ignore if message has different origin" do
    expect(@connection).to receive(:send_reply).with(/testing message echo ignoring/)

    foo_flow = flow_data("example/foo")
    main_flow = flow_data("example_main")
    message = {:flow => foo_flow["id"], :app => "chat", :event => "message", :content => "testing message echo ignoring"}
    @connection.instance_variable_set(:@outgoing_messages, [message.merge(:flow => main_flow)])
    @connection.channels["example/main"] = IrcChannel.new(@connection, main_flow)
    @connection.channels["example/foo"] = IrcChannel.new(@connection, foo_flow)
    @connection.send(:receive_flowdock_event, MultiJson.dump(message.merge(:user => 1)))
  end

  it "should send PING messages" do
    expect(@connection).to receive(:last_ping_sent=).with(/FLOWDOCK-/)
    expect(@connection).to receive(:send_reply).with(/PING/)
    @connection.ping!
  end

  describe "process_current_user" do
    it "should find the current user and set user_id, email, real_name and nick" do
      @connection.send(:process_current_user, fixture("user"))

      expect(@connection.user_id).to eq(1)
      expect(@connection.email).to eq("otto@example.com")
      expect(@connection.nick).to eq("Otto")
      expect(@connection.real_name).to eq("Otto Hilska")
    end
  end

  describe "receiving data" do
    it "should parse a single line of text" do
      expect(@connection).to receive(:parse_line).once.with("NICK test")
      @connection.receive_data("NICK test\r\n")
    end

    it "should parse multiple lines of text" do
      counter = 0
      expect(@connection).to receive(:parse_line).twice do |data|
        expect(["NICK mutru", "USER mutru mutru localhost :Otto Hilska"].include?(data)).to eq(true)
      end

      @connection.receive_data("NICK mutru\r\nUSER mutru mutru localhost :Otto Hilska\r\n")
    end

    it "should parse partial lines correctly" do
      expect(@connection).to receive(:parse_line).twice do |data|
        expect(["NICK mutru", "USER mutru mutru localhost :Otto Hilska"].include?(data)).to eq(true)
      end
      @connection.receive_data("NICK mutru\r\nUSER ")
      @connection.receive_data("mutru mutru localhost :Otto Hilska\r\n")
    end
  end

  describe "adding and removing channels" do
    it "should remove channel" do
      @connection.channels = {'irc/ottotest' => example_irc_channel(@connection), 'irc/ottotest2' => example_irc_channel(@connection)}
      @connection.remove_channel(@connection.channels['irc/ottotest'])
      expect(@connection.channels.keys).to eq(['irc/ottotest2'])
    end

    it "should add new channel and retrieve it's data" do
      expect(@connection).to receive(:update_channel) do |channel|
        expect(channel).to be_an_instance_of(IrcChannel)
        expect(channel.id).to eq('irc:ottotest')
        expect(channel.send(:open?)).to eq(false)
      end

      @connection.add_channel({'id' => 'irc:ottotest', 'open' => true})
    end
  end

  describe "finding users and channels" do
    before(:each) do
      @connection.channels = {'irc/ottotest' => example_irc_channel(@connection)}
    end

    it "should find channel with its Flowdock ID" do
      id = @connection.channels["irc/ottotest"].id
      expect(@connection.find_channel_by_id(id).irc_id).to eq("#irc/ottotest")
    end

    it "should find channel with its IRC ID" do
      expect(@connection.find_channel_by_name('#irc/ottotest').flowdock_id).to eq('irc/ottotest')
    end

    it "should return nil when a channel is not found" do
      expect(@connection.find_channel('DOES_NOT_EXIST')).to be_nil
    end

    it "should return when querying channel with name nil" do
      expect(@connection.find_channel(nil)).to be_nil
    end

    it "should find users by ID" do
      user = @connection.find_user_by_id(1)
      expect(user).to be_a(User)
      expect(user.id).to eq(1)
      expect(user.nick).to eq('Otto')
    end

    it "should return nil when users are not found by ID" do
      expect(@connection.find_user_by_id(2)).to be_nil
    end

    it "should return nil when querying user by nil ID" do
      expect(@connection.find_user_by_id(nil)).to be_nil
    end

    it "should find users by nick, case insensitively" do
      user = @connection.find_user_by_nick('otTo')
      expect(user).to be_a(User)
      expect(user.id).to eq(1)
      expect(user.nick).to eq('Otto')
    end

    it "should return nil when users are not found by nick" do
      expect(@connection.find_user_by_nick('WHATEVER')).to be_nil
    end

    it "should return nil when querying user by nil nick" do
      expect(@connection.find_user_by_nick(nil)).to be_nil
    end

    it "should resolve nick conflicts" do
      @connection.send(:process_current_user, 1)
      @connection.send(:resolve_nick_conflicts!)
      user = @connection.find_user_by_nick('OTTOMOB2')
      expect(user).to be_a(User)
      expect(user.id).to eq(50002)
      expect(user.name).to eq('Fake ottomob')
    end
  end

  describe "posting messages" do
    it "should post channel messages" do
      EventMachine.run {
        @connection.email = "foo@example.com"
        @connection.password = "supersecret"
        channel = IrcChannel.new(@connection, flow_data("example/main"))

        stub_request(:post, "https://api.example.com/flows/#{channel.flowdock_id}/messages").
          with(:body => /Hello world!/,
            :headers => { 'Authorization' => ['foo@example.com', 'supersecret'],
              'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "", :headers => {})

        @connection.post_chat_message(channel, 'Hello world!')
        EventMachine.stop
      }
    end

    it "should post private messages" do
      EventMachine.run {
        @connection.email = "foo@example.com"
        @connection.password = "supersecret"
        @connection.channels = {'irc/ottotest' => example_irc_channel(@connection)}
        user = @connection.find_user_by_id(1)
        expect(user).to be_a(User)

        stub_request(:post, "https://api.flowdock.com/private/#{user.flowdock_id}/messages").
          with(:body => /Hello user!/,
            :headers => { 'Authorization' => ['foo@example.com', 'supersecret'],
              'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "", :headers => {})

        @connection.post_chat_message(user, 'Hello user!')
        EventMachine.stop
      }
    end
  end

  it "should have a send_reply method for posting data to the client, adding newlines" do
    expect(@connection).to receive(:send_data).with("foo\r\n")
    @connection.send_reply("foo")
  end

  it "should reset FlowdockConnection when setting an away message" do
    old_state = @connection.authenticated?
    @connection.instance_variable_set(:@authenticated, true)
    expect_any_instance_of(FlowdockConnection).to receive(:start!)
    @connection.set_away("gone")
    expect(@connection.away_message).to eq("gone")
    @connection.instance_variable_set(:@authenticated, old_state)
  end

  it "should not reset FlowdockConnection again when changing from away message to another" do
    old_state = @connection.authenticated?
    @connection.instance_variable_set(:@authenticated, true)
    expect_any_instance_of(FlowdockConnection).to receive(:start!).once
    @connection.set_away("gone")
    expect(@connection.away_message).to eq("gone")
    @connection.set_away("gone more") # start! not called anymore
    expect(@connection.away_message).to eq("gone more")
    @connection.instance_variable_set(:@authenticated, old_state)
  end

  it "should not try to reset FlowdockConnection when setting an away message and not authenticated" do
    old_state = @connection.authenticated?
    @connection.instance_variable_set(:@authenticated, false)
    expect_any_instance_of(FlowdockConnection).not_to receive(:start!)
    @connection.set_away("gone")
    expect(@connection.away_message).to eq("gone")
    @connection.instance_variable_set(:@authenticated, old_state)
  end

end
