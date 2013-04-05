require 'spec_helper'

describe JoinCommand do
  it "should not send anything when authenticated and joining existing channel" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    irc_connection.stub!(:find_channel_by_name).and_return(channel)
    irc_connection.should_not_receive(:send_reply)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should join the channel if authenticated and channel is closed" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@example.com', :password => 'password', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    channel.should_receive(:open?).exactly(2).times.and_return(false, true)
    irc_connection.stub!(:find_channel_by_name).and_return(channel)
    irc_connection.should_receive(:update_flow).and_yield
    irc_connection.should_receive(:update_channel).and_yield

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return channel temporarily unavailable if join (API call) failed" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@example.com', :password => 'password', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    channel.should_receive(:open?).exactly(2).times.and_return(false, false)
    irc_connection.stub!(:find_channel_by_name).and_return(channel)
    irc_connection.should_receive(:update_flow).and_yield
    irc_connection.should_receive(:update_channel).and_yield
    irc_connection.should_not_receive(:restart_flowdock_connection!)
    irc_connection.should_receive(:send_reply).with(/#irc\/ottotest :Channel temporarily unavailable/)
  
    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    cmd.valid?.should be_true
    cmd.execute!
  end
  it "should send error if authenticated, but channel does not exist" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    irc_connection.stub!(:find_channel_by_name).and_return(nil)
    irc_connection.should_receive(:send_reply).with(/403 Otto #test :No such channel/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#test"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should send error if not authenticated" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    irc_connection.should_receive(:send_reply).with(/403 Otto #test :No such channel/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#test"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should handle multiple channels in a single JOIN command" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    irc_connection.should_receive(:send_reply).with(/403 Otto #test :No such channel/)
    irc_connection.should_receive(:send_reply).with(/403 Otto #test2 :No such channel/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#test,#test2"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
