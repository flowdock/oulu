require 'spec_helper'

describe JoinCommand do
  it "should not send anything when authenticated and joining existing channel" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    irc_connection.stub!(:find_channel).and_return(true)
    irc_connection.should_not_receive(:send_reply).with(/No such channel/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should send error if authenticated, but channel does not exist" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    irc_connection.stub!(:find_channel).and_return(false)
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
end
