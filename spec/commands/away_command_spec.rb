describe AwayCommand do
  it "should set IRC connection's AWAY message" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :registered? => true,
      :nick => 'Otto')
    irc_connection.should_receive(:send_reply).with(/You have been marked as being away/)
    irc_connection.should_receive(:set_away).with("gone somewhere, brb")

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data(["gone somewhere, brb"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should unset IRC connection's AWAY message" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :registered? => true,
      :nick => 'Otto')
    irc_connection.should_receive(:send_reply).with(/You are no longer marked as being away/)
    irc_connection.should_receive(:set_away).with(nil)

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data([])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should unset AWAY message with an empty string as well" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :registered? => true,
      :nick => 'Otto')
    irc_connection.should_receive(:send_reply).with(/You are no longer marked as being away/)
    irc_connection.should_receive(:set_away).with(nil)

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data([""]) # empty string instead of empty array
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should set AWAY message even when not authenticated" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :registered? => true,
      :nick => 'Otto')
    irc_connection.should_receive(:send_reply).with(/You have been marked as being away/)
    irc_connection.should_receive(:set_away).with("gone somewhere, brb")

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data(["gone somewhere, brb"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "shouldn't do anything when not registered" do
    irc_connection = mock(:irc_connection, :registered? => false,
      :nick => 'Otto')
    irc_connection.should_not_receive(:set_away)

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data(["gone"])
    cmd.valid?.should be_false
  end
end
