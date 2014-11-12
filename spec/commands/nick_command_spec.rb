describe NickCommand do
  it "should configure IRC connection during registration" do
    irc_connection = double(:irc_connection, :authenticated? => false, :registered? => false,
      :nick => nil, :email => nil)
    expect(irc_connection).not_to receive(:send_reply)
    expect(irc_connection).to receive(:nick=).with("Newnick")

    cmd = NickCommand.new(irc_connection)
    cmd.set_data(["Newnick"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should send a PING if it completed registration" do
    irc_connection = double(:irc_connection, :authenticated? => false,
      :nick => nil, :email => "otto@example.com", :real_name => "Otto", :last_ping_sent => nil, :password => nil)
    expect(irc_connection).to receive(:nick=).with("Newnick")
    expect(irc_connection).to receive(:registered?).exactly(2).times.and_return(false, true)
    expect(irc_connection).to receive(:send_reply).with(/Welcome to the Internet Relay Network.*End of MOTD.*NickServ.*identify/m)
    expect(irc_connection).to receive(:ping!)

    cmd = NickCommand.new(irc_connection)
    cmd.set_data(["Newnick"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should not allow changing the nick after registration" do
    irc_connection = double(:irc_connection, :authenticated? => false, :registered? => true,
      :nick => "Oldnick", :email => "otto@example.com")
    expect(irc_connection).to receive(:send_reply).with(/Erroneous nickname/)
    expect(irc_connection).not_to receive(:nick=)

    cmd = NickCommand.new(irc_connection)
    cmd.set_data(["Newnick"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should start PASS authentication if it completed registration and password is given" do
    irc_connection = double(:irc_connection, :authenticated? => false, :registered? => false, :last_ping_sent => nil, :nick => nil, :email => "otto@example.com", :password => "password")
    expect(irc_connection).to receive(:nick=).with("otto")
    expect(irc_connection).to receive(:registered?).exactly(2).times.and_return(false, true)
    expect(irc_connection).to receive(:send_reply).with(/Welcome to the Internet Relay Network.*Message of the day.*End of MOTD/m)
    expect(irc_connection).not_to receive(:send_reply).with(/NickServ.*identify/m)
    expect(irc_connection).to receive(:ping!)

    cmd = NickCommand.new(irc_connection)
    expect(cmd).to receive(:authentication_send).with("otto@example.com", "password").and_yield
    cmd.set_data(["otto"])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
