require 'spec_helper'

describe ModeCommand do
  it "should return user's own user mode" do
    irc_connection = double(:irc_connection, :nick => 'Otto')
    expect(irc_connection).to receive(:send_reply).with(/Otto.*\+i/)

    cmd = ModeCommand.new(irc_connection)
    cmd.set_data(["otto"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should return a channel's mode" do
    irc_connection = double(:irc_connection, :nick => 'Otto')
    channel = example_irc_channel(irc_connection)
    expect(irc_connection).to receive(:send_reply).with(/#irc\/ottotest.*\+is/)
    expect(irc_connection).to receive(:find_channel_by_name).with("#irc/ottotest").and_return(channel)

    cmd = ModeCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should return a channel's ban list" do
    irc_connection = double(:irc_connection, :nick => 'Otto')
    channel = example_irc_channel(irc_connection)
    expect(irc_connection).to receive(:send_reply).with(/#irc\/ottotest.*End of Channel Ban List/)
    expect(irc_connection).to receive(:find_channel_by_name).with("#irc/ottotest").and_return(channel)

    cmd = ModeCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest", "+b"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  # TODO: Obviously, there's a lot more MODE could do.
end
