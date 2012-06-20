describe NickCommand do
  it "should configure IRC connection during registration" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :registered? => false,
      :nick => nil, :email => "otto@unknown")
    irc_connection.should_not_receive(:send_reply)
    irc_connection.should_receive(:nick=).with("Newnick")

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
