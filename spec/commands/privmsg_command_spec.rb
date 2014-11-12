require 'spec_helper'

describe PrivmsgCommand do
  it "should allow non-authenticated users to message NickServ and authenticate" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :email => 'otto@unknown', :registered? => true)
    channel = example_irc_channel(irc_connection)
    channels = {}
    channels[channel.flowdock_id] = channel
    allow(irc_connection).to receive(:channels).and_return(channels)
    expect(irc_connection).to receive(:authenticated?).exactly(3).times.and_return(false, true, true) # first not authenticated, then suddenly is!
    expect(irc_connection).to receive(:authenticate).with("some@example.com", "verysecret").and_yield(true, "Authentication failed. Check username and password and try again.").and_yield(nil, nil)
    expect(irc_connection).to receive(:send_reply).with(/Authentication failed/m).once
    expect(irc_connection).to receive(:send_reply).with(/NICK.*JOIN.*End of NAMES/m).once

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "identify some@example.com verysecret"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should not join channels when something with NickServ authentication goes wrong" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :email => 'otto@unknown', :registered? => true)
    channel = example_irc_channel(irc_connection)
    channels = {}
    channels[channel.flowdock_id] = channel
    allow(irc_connection).to receive(:channels).and_return(channels)
    expect(irc_connection).to receive(:authenticated?).exactly(2).times.and_return(false, false) # not authenticated, even on the second attempt
    expect(irc_connection).to receive(:authenticate).with("some@example.com", "verysecret").and_yield(true, "Authentication failed. Check username and password and try again.")
    expect(irc_connection).to receive(:send_reply).with(/Authentication failed/).once

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "identify some@example.com verysecret"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should show subscription instructions if there are no channels to join to" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :email => 'otto@unknown', :registered? => true)
    channels = {}
    allow(irc_connection).to receive(:channels).and_return(channels)
    expect(irc_connection).to receive(:authenticated?).exactly(2).times.and_return(false, false) # not authenticated, even on the second attempt
    expect(irc_connection).to receive(:authenticate).with("some@example.com", "verysecret").and_yield(true, "No access to flows.\nLog in and check your current subscription status.")
    expect(irc_connection).to receive(:send_reply).with(/No access to flows.*\n.*current subscription status/).once

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "identify some@example.com verysecret"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should not blow up when messaging random crap to NickServ" do
    irc_connection = double(:irc_connection, :authenticated? => false, :nick => 'Otto', :email => 'otto@unknown', :registered? => true)
    expect(irc_connection).not_to receive(:send_reply)

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "blaargh"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should allow users to message channels" do
    irc_connection = double(:irc_connection, :authenticated? => true, :registered? => true, :nick => "TestUser", :email => "test@example.com")
    channel = example_irc_channel(irc_connection)
    expect(irc_connection).to receive(:find_channel_by_name).with(channel.irc_id).and_return(channel)
    expect(irc_connection).not_to receive(:find_user_by_nick)
    expect(irc_connection).to receive(:post_chat_message).with(channel, "Hello world!")

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([channel.irc_id, "Hello world!"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should allow users to message other users" do
    irc_connection = double(:irc_connection, :authenticated? => true, :registered? => true, :nick => "TestUser", :email => "test@example.com")
    channel = example_irc_channel(irc_connection)
    target_user = channel.users[1]
    expect(irc_connection).to receive(:find_channel_by_name).with(target_user.nick).and_return(nil)
    expect(irc_connection).to receive(:find_user_by_nick).with(target_user.nick).and_return(target_user)
    expect(irc_connection).to receive(:post_chat_message).with(target_user, "Hello world!")

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([target_user.nick, "Hello world!"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should intercept messages sent to self and echo back" do
    irc_connection = double(:irc_connection, :authenticated? => true, :registered? => true, :nick => "TestUser", :email => "test@example.com")
    channel = example_irc_channel(irc_connection)
    target_nick = irc_connection.nick
    expect(irc_connection).not_to receive(:find_channel_by_name)
    expect(irc_connection).not_to receive(:find_user_by_nick)
    expect(irc_connection).not_to receive(:post_chat_message)
    expect(irc_connection).to receive(:send_reply).with(/PRIVMSG #{target_nick} :Hello world!$/)

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([target_nick, "Hello world!"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should send /me messages as status updates" do
    irc_connection = double(:irc_connection, :authenticated? => true, :registered? => true, :nick => "TestUser", :email => "test@example.com")
    channel = example_irc_channel(irc_connection)
    expect(irc_connection).to receive(:find_channel_by_name).with(channel.irc_id).and_return(channel)
    expect(irc_connection).to receive(:post_status_message).with(channel, "my status")

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([channel.irc_id, "\u0001ACTION my status\u0001"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should return an error when trying to message targets that are not available" do
    irc_connection = double(:irc_connection, :authenticated? => true, :nick => 'Otto', :registered? => true, :email => "test@example.com")
    channel = example_irc_channel(irc_connection)
    expect(irc_connection).to receive(:find_channel_by_name).with(channel.irc_id).and_return(nil)
    expect(irc_connection).to receive(:find_user_by_nick).with(channel.irc_id).and_return(nil)
    expect(irc_connection).to receive(:send_reply).with(/No such nick\/channel/)

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([channel.irc_id, "Hello world!"])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
