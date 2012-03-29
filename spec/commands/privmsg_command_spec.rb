require 'spec_helper'

describe PrivmsgCommand do
  it "should allow non-authenticated users to message NickServ and authenticate" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@unknown')
    channel = example_irc_channel(irc_connection)
    channels = {}
    channels[channel.flowdock_id] = channel
    irc_connection.stub!(:channels).and_return(channels)
    irc_connection.should_receive(:authenticated?).exactly(2).times.and_return(false, true) # first not authenticated, then suddenly is!
    irc_connection.should_receive(:authenticate).with("some@example.com", "verysecret").and_yield
    irc_connection.should_receive(:send_reply).with(/NICK.*JOIN.*End of NAMES/m)

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "identify some@example.com verysecret"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not join channels when something with NickServ authentication goes wrong" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@unknown')
    channel = example_irc_channel(irc_connection)
    channels = {}
    channels[channel.flowdock_id] = channel
    irc_connection.stub!(:channels).and_return(channels)
    irc_connection.should_receive(:authenticated?).exactly(2).times.and_return(false, false) # not authenticated, even on the second attempt
    irc_connection.should_receive(:authenticate).with("some@example.com", "verysecret").and_yield
    irc_connection.should_receive(:send_reply).with(/Authentication failed/)

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "identify some@example.com verysecret"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not blow up when messaging random crap to NickServ" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :nick => 'Otto', :email => 'otto@unknown')
    irc_connection.should_not_receive(:send_reply)

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data(["nickserv", "blaargh"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should allow users to message channels" do
    irc_connection = mock(:irc_connection, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:find_channel).with(channel.irc_id).and_return(channel)
    irc_connection.should_receive(:post_message).with(channel.flowdock_id, "Hello world!")

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([channel.irc_id, "Hello world!"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return an error when trying to message targets that are not channels" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :nick => 'Otto')
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:find_channel).with(channel.irc_id).and_return(nil)
    irc_connection.should_receive(:send_reply).with(/No such nick\/channel/)

    cmd = PrivmsgCommand.new(irc_connection)
    cmd.set_data([channel.irc_id, "Hello world!"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
