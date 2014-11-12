require 'spec_helper'

describe PartCommand do
  it "should part the channel if authenticated and channel is open" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :email => 'otto@example.com', :password => 'password', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    expect(channel).to receive(:open?).once.and_return(true)
    allow(irc_connection).to receive(:find_channel_by_name).and_return(channel)
    expect(irc_connection).to receive(:update_flow).and_yield
    expect(irc_connection).to receive(:send_reply).with(/PART #irc\/ottotest/)

    cmd = PartCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should send error if authenticated, but channel does not exist" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    allow(irc_connection).to receive(:find_channel_by_name).and_return(nil)
    expect(irc_connection).to receive(:send_reply).with(/403 Otto #test :No such channel/)

    cmd = PartCommand.new(irc_connection)
    cmd.set_data(["#test"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should send error if not authenticated" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    expect(irc_connection).to receive(:send_reply).with(/403 Otto #test :No such channel/)

    cmd = PartCommand.new(irc_connection)
    cmd.set_data(["#test"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should handle multiple channels in a single PART command" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    expect(irc_connection).to receive(:send_reply).with(/403 Otto #test :No such channel/)
    expect(irc_connection).to receive(:send_reply).with(/403 Otto #test2 :No such channel/)

    cmd = JoinCommand.new(irc_connection)
    cmd.set_data(["#test,#test2"])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
