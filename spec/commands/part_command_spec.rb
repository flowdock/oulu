require 'spec_helper'

describe PartCommand do
  it "should part the channel if authenticated and channel is open" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@example.com', :password => 'password', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    channel.should_receive(:open?).once.and_return(true)
    irc_connection.stub!(:find_channel_by_name).and_return(channel)
    channel.should_receive(:part!)
    irc_connection.should_receive(:update_flow)
    irc_connection.should_receive(:send_reply).with(/PART #irc\/ottotest/)
  
    cmd = PartCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should send error if authenticated, but channel does not exist" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    irc_connection.stub!(:find_channel_by_name).and_return(nil)
    irc_connection.should_receive(:send_reply).with(/403 Otto #test :No such channel/)

    cmd = PartCommand.new(irc_connection)
    cmd.set_data(["#test"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should send error if not authenticated" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    irc_connection.should_receive(:send_reply).with(/403 Otto #test :No such channel/)

    cmd = PartCommand.new(irc_connection)
    cmd.set_data(["#test"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should handle multiple channels in a single PART command" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    irc_connection.should_receive(:send_reply).with(/403 Otto #test :No such channel/)
    irc_connection.should_receive(:send_reply).with(/403 Otto #test2 :No such channel/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#test,#test2"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
