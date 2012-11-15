require 'spec_helper'

describe PrivmsgCommand do
  it "should allow non-authenticated users to message NickServ and authenticate" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@unknown', :registered? => true)
    channel = example_irc_channel(irc_connection)
    channels = {}
    channels[channel.flowdock_id] = channel
    irc_connection.stub!(:channels).and_return(channels)
    irc_connection.should_receive(:authenticated?).exactly(3).times.and_return(false, true, true) # first not authenticated, then suddenly is!
    irc_connection.should_receive(:authenticate).with("some@example.com", "verysecret").and_yield(true, "Authentication failed. Check username and password and try again.").and_yield(nil, nil)
    irc_connection.should_receive(:send_reply).with(/Authentication failed/m).once
    irc_connection.should_receive(:send_reply).with(/NICK.*JOIN.*End of NAMES/m).once

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "identify some@example.com verysecret"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not join channels when something with NickServ authentication goes wrong" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@unknown', :registered? => true)
    channel = example_irc_channel(irc_connection)
    channels = {}
    channels[channel.flowdock_id] = channel
    irc_connection.stub!(:channels).and_return(channels)
    irc_connection.should_receive(:authenticated?).exactly(2).times.and_return(false, false) # not authenticated, even on the second attempt
    irc_connection.should_receive(:authenticate).with("some@example.com", "verysecret").and_yield(true, "Authentication failed. Check username and password and try again.")
    irc_connection.should_receive(:send_reply).with(/Authentication failed/).once

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "identify some@example.com verysecret"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should show subscription instructions if there are no channels to join to" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@unknown', :registered? => true)
    channels = {}
    irc_connection.stub!(:channels).and_return(channels)
    irc_connection.should_receive(:authenticated?).exactly(2).times.and_return(false, false) # not authenticated, even on the second attempt
    irc_connection.should_receive(:authenticate).with("some@example.com", "verysecret").and_yield(true, "No access to flows.\nLog in and check your current subscription status.")
    irc_connection.should_receive(:send_reply).with(/No access to flows.*\n.*current subscription status/).once

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "identify some@example.com verysecret"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not blow up when messaging random crap to NickServ" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :nick => 'Otto', :email => 'otto@unknown', :registered? => true)
    irc_connection.should_not_receive(:send_reply)

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "blaargh"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should allow users to message channels" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :registered? => true)
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:find_channel).with(channel.irc_id).and_return(channel)
    irc_connection.should_not_receive(:find_user_by_nick)
    irc_connection.should_receive(:post_chat_message).with(channel, "Hello world!")

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([channel.irc_id, "Hello world!"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should allow users to message other users" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :registered? => true)
    channel = example_irc_channel(irc_connection)
    target_user = channel.users[1]
    irc_connection.should_receive(:find_channel).with(target_user.nick).and_return(nil)
    irc_connection.should_receive(:find_user_by_nick).with(target_user.nick).and_return(target_user)
    irc_connection.should_receive(:post_chat_message).with(target_user, "Hello world!")

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([target_user.nick, "Hello world!"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should send /me messages as status updates" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :registered? => true)
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:find_channel).with(channel.irc_id).and_return(channel)
    irc_connection.should_receive(:post_status_message).with(channel, "my status")

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([channel.irc_id, "\u0001ACTION my status\u0001"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return an error when trying to message targets that are not available" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :nick => 'Otto', :registered? => true)
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:find_channel).with(channel.irc_id).and_return(nil)
    irc_connection.should_receive(:find_user_by_nick).with(channel.irc_id).and_return(nil)
    irc_connection.should_receive(:send_reply).with(/No such nick\/channel/)

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([channel.irc_id, "Hello world!"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
