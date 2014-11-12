describe AwayCommand do
  it "should set IRC connection's AWAY message" do
    irc_connection = double(:irc_connection, :authenticated? => true, :registered? => true,
      :nick => 'Otto')
    expect(irc_connection).to receive(:send_reply).with(/You have been marked as being away/)
    expect(irc_connection).to receive(:set_away).with("gone somewhere, brb")

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data(["gone somewhere, brb"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should unset IRC connection's AWAY message" do
    irc_connection = double(:irc_connection, :authenticated? => true, :registered? => true,
      :nick => 'Otto')
    expect(irc_connection).to receive(:send_reply).with(/You are no longer marked as being away/)
    expect(irc_connection).to receive(:set_away).with(nil)

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data([])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should unset AWAY message with an empty string as well" do
    irc_connection = double(:irc_connection, :authenticated? => true, :registered? => true,
      :nick => 'Otto')
    expect(irc_connection).to receive(:send_reply).with(/You are no longer marked as being away/)
    expect(irc_connection).to receive(:set_away).with(nil)

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data([""]) # empty string instead of empty array
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should set AWAY message even when not authenticated" do
    irc_connection = double(:irc_connection, :authenticated? => false, :registered? => true,
      :nick => 'Otto')
    expect(irc_connection).to receive(:send_reply).with(/You have been marked as being away/)
    expect(irc_connection).to receive(:set_away).with("gone somewhere, brb")

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data(["gone somewhere, brb"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "shouldn't do anything when not registered" do
    irc_connection = double(:irc_connection, :registered? => false,
      :nick => 'Otto')
    expect(irc_connection).not_to receive(:set_away)

    cmd = AwayCommand.new(irc_connection)
    cmd.set_data(["gone"])
    expect(cmd).not_to be_valid
  end
end
