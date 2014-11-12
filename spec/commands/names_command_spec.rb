require 'spec_helper'

describe NamesCommand do
  it "should list nicks of channel users and the end command" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true)
    channel_hash = Yajl::Parser.parse(fixture('flows')).first
    channel = IrcChannel.new(irc_connection, channel_hash)
    expect(irc_connection).to receive(:find_channel_by_name).and_return(channel)
    expect(irc_connection).to receive(:send_reply).with(/Ottomob.*End of NAMES/m)

    cmd = NamesCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should tell when the channel does not exist" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true)
    expect(irc_connection).to receive(:find_channel_by_name).and_return(nil)
    expect(irc_connection).to receive(:send_reply).with(/No such nick\/channel/)

    cmd = NamesCommand.new(irc_connection)
    cmd.set_data(["#doesnotexist"])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
