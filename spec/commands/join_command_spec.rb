require 'spec_helper'

describe JoinCommand do
  it "should not send anything when authenticated and joining existing channel" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    allow(irc_connection).to receive(:find_channel_by_name).and_return(channel)
    expect(irc_connection).not_to receive(:send_reply)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should join the channel if authenticated and channel is closed" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :email => 'otto@example.com', :password => 'password', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    expect(channel).to receive(:open?).exactly(2).times.and_return(false, true)
    allow(irc_connection).to receive(:find_channel_by_name).and_return(channel)
    expect(irc_connection).to receive(:update_flow).and_yield
    expect(irc_connection).to receive(:update_channel).and_yield

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should return channel temporarily unavailable if join (API call) failed" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :email => 'otto@example.com', :password => 'password', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    expect(channel).to receive(:open?).exactly(2).times.and_return(false, false)
    allow(irc_connection).to receive(:find_channel_by_name).and_return(channel)
    expect(irc_connection).to receive(:update_flow).and_yield
    expect(irc_connection).to receive(:update_channel).and_yield
    expect(irc_connection).not_to receive(:restart_flowdock_connection!)
    expect(irc_connection).to receive(:send_reply).with(/#irc\/ottotest :Channel temporarily unavailable/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    expect(cmd).to be_valid
    cmd.execute!
  end
  it "should send error if authenticated, but channel does not exist" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    allow(irc_connection).to receive(:find_channel_by_name).and_return(nil)
    expect(irc_connection).to receive(:send_reply).with(/403 Otto #test :No such channel/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#test"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should send error if not authenticated" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    expect(irc_connection).to receive(:send_reply).with(/403 Otto #test :No such channel/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#test"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should handle multiple channels in a single JOIN command" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    expect(irc_connection).to receive(:send_reply).with(/403 Otto #test :No such channel/)
    expect(irc_connection).to receive(:send_reply).with(/403 Otto #test2 :No such channel/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#test,#test2"])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
