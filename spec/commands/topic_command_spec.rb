require 'spec_helper'

describe TopicCommand do
  it "should display topic when channel is found" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:find_channel_by_name).with("#irc/ottotest").and_return(channel)
    irc_connection.should_receive(:send_reply).with(":#{IrcServer::HOST} 332 Otto #irc\/ottotest :Ottotest (IRC Systems)")

    cmd = TopicCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return Not on channel when channel is not found" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    irc_connection.should_receive(:find_channel_by_name).with("#foobar").and_return(nil)
    irc_connection.should_receive(:send_reply).with(/403 Otto #foobar :No such channel/)

    cmd = TopicCommand.new(irc_connection)
    cmd.set_data(["#foobar"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return No channel modes error when trying to set new topic" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:find_channel_by_name).with("#irc/ottotest").and_return(channel)
    irc_connection.should_receive(:send_reply).with(/477 Otto #irc\/ottotest :Channel doesn't support modes/)

    cmd = TopicCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest", "New topic!"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
