describe NamesCommand do
  it "should list nicks of channel users and the end command" do
    irc_connection = mock(:irc_connection, :nick => 'Otto')
    channel_hash = Yajl::Parser.parse(fixture('flows')).first
    channel = IrcChannel.new(irc_connection, channel_hash)
    irc_connection.should_receive(:find_channel).and_return(channel)
    irc_connection.should_receive(:send_reply).with(/Ottomob.*End of NAMES/m)

    cmd = NamesCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should tell when the channel does not exist" do
    irc_connection = mock(:irc_connection, :nick => 'Otto')
    irc_connection.should_receive(:find_channel).and_return(nil)
    irc_connection.should_receive(:send_reply).with(/No such nick\/channel/)

    cmd = NamesCommand.new(irc_connection)
    cmd.set_data(["#doesnotexist"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
