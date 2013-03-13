require 'spec_helper'

describe ModeCommand do
  it "should return user's own user mode" do
    irc_connection = mock(:irc_connection, :nick => 'Otto')
    irc_connection.should_receive(:send_reply).with(/Otto.*\+i/)

    cmd = ModeCommand.new(irc_connection)
    cmd.set_data(["otto"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return a channel's mode" do
    irc_connection = mock(:irc_connection, :nick => 'Otto')
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:send_reply).with(/#irc\/ottotest.*\+is/)
    irc_connection.should_receive(:find_channel_by_name).with("#irc/ottotest").and_return(channel)

    cmd = ModeCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return a channel's ban list" do
    irc_connection = mock(:irc_connection, :nick => 'Otto')
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:send_reply).with(/#irc\/ottotest.*End of Channel Ban List/)
    irc_connection.should_receive(:find_channel_by_name).with("#irc/ottotest").and_return(channel)

    cmd = ModeCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest", "+b"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  # TODO: Obviously, there's a lot more MODE could do.
end
