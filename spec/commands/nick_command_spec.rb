describe NickCommand do
  it "should configure IRC connection during registration" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :registered? => false,
      :nick => nil, :email => nil)
    irc_connection.should_not_receive(:send_reply)
    irc_connection.should_receive(:nick=).with("Newnick")

    cmd = NickCommand.new(irc_connection)
    cmd.set_data(["Newnick"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should send a PING if it completed registration" do
    irc_connection = mock(:irc_connection, :authenticated? => false,
      :nick => nil, :email => "otto@example.com", :real_name => "Otto", :last_ping_sent => nil)
    irc_connection.should_receive(:nick=).with("Newnick")
    irc_connection.should_receive(:registered?).exactly(2).times.and_return(false, true)
    irc_connection.should_receive(:ping!)

    cmd = NickCommand.new(irc_connection)
    cmd.set_data(["Newnick"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not allow changing the nick after registration" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :registered? => true,
      :nick => "Oldnick", :email => "otto@example.com")
    irc_connection.should_receive(:send_reply).with(/Erroneous nickname/)
    irc_connection.should_not_receive(:nick=)

    cmd = NickCommand.new(irc_connection)
    cmd.set_data(["Newnick"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
