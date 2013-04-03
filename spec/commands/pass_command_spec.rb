require 'spec_helper'

describe PassCommand do
  it "should not be valid when already registered tries PASS" do
    irc_connection = mock(:irc_connection, :registered? => true)

    cmd = PassCommand.new(irc_connection)
    cmd.set_data(["otto.hilska@nodeta.fi","omasalasana"])
    cmd.should_not be_valid
  end

  it "should not be valid when args is nil" do
    irc_connection = mock(:irc_connection, :registered? => false)

    cmd = PassCommand.new(irc_connection)
    cmd.set_data([])
    cmd.should_not be_valid
  end

  it "should accept credentials in two params" do
    irc_connection = mock(:irc_connection, :registered? => false, :email => nil)
    irc_connection.should_receive(:password=).with("password")
    irc_connection.should_receive(:email=).with("example@example.com")

    cmd = PassCommand.new(irc_connection)
    cmd.set_data(["example@example.com","password"])
    cmd.execute!
  end

  it "should accept credentials in one param" do
    irc_connection = mock(:irc_connection, :registered? => false, :email => nil)
    irc_connection.should_receive(:password=).with("password")
    irc_connection.should_receive(:email=).with("example@example.com")

    cmd = PassCommand.new(irc_connection)
    cmd.set_data(["example@example.com password"])
    cmd.execute!
  end

  it "should accept password with space" do
    irc_connection = mock(:irc_connection, :registered? => false, :email => nil)
    irc_connection.should_receive(:password=).with("password with spaces")
    irc_connection.should_receive(:email=).with("example@example.com")

    cmd = PassCommand.new(irc_connection)
    cmd.set_data(["example@example.com password with spaces"])
    cmd.execute!
  end
end
