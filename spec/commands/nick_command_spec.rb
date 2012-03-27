describe NickCommand do
  it "should reply with a new nick and configure IRC connection" do
    irc_connection = mock(:irc_connection, :authenticated? => false,
      :nick => "Oldnick", :email => "otto@example.com")
    irc_connection.should_receive(:send_reply).with(/NICK :Newnick/)
    irc_connection.should_receive(:nick=).with("Newnick")

    cmd = NickCommand.new(irc_connection)
    cmd.set_data(["Newnick"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not change the allow changing a nick when you're already authenticated" do
    irc_connection = mock(:irc_connection, :authenticated? => true,
      :nick => "Oldnick", :email => "otto@example.com")
    irc_connection.should_receive(:send_reply).with(/Erroneous nickname/)
    irc_connection.should_not_receive(:nick=)

    cmd = NickCommand.new(irc_connection)
    cmd.set_data(["Newnick"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
