require 'spec_helper'

describe PassCommand do
  it "should not be valid when already registered tries PASS" do
    irc_connection = double(:irc_connection, :registered? => true)

    cmd = PassCommand.new(irc_connection)
    cmd.set_data(["otto.hilska@nodeta.fi","omasalasana"])
    expect(cmd).not_to be_valid
  end

  it "should not be valid when args is nil" do
    irc_connection = double(:irc_connection, :registered? => false)

    cmd = PassCommand.new(irc_connection)
    cmd.set_data([])
    expect(cmd).not_to be_valid
  end

  it "should accept credentials in two params" do
    irc_connection = double(:irc_connection, :registered? => false, :email => nil)
    expect(irc_connection).to receive(:password=).with("password")
    expect(irc_connection).to receive(:email=).with("example@example.com")

    cmd = PassCommand.new(irc_connection)
    cmd.set_data(["example@example.com","password"])
    cmd.execute!
  end

  it "should accept credentials in one param" do
    irc_connection = double(:irc_connection, :registered? => false, :email => nil)
    expect(irc_connection).to receive(:password=).with("password")
    expect(irc_connection).to receive(:email=).with("example@example.com")

    cmd = PassCommand.new(irc_connection)
    cmd.set_data(["example@example.com password"])
    cmd.execute!
  end

  it "should accept password with space" do
    irc_connection = double(:irc_connection, :registered? => false, :email => nil)
    expect(irc_connection).to receive(:password=).with("password with spaces")
    expect(irc_connection).to receive(:email=).with("example@example.com")

    cmd = PassCommand.new(irc_connection)
    cmd.set_data(["example@example.com password with spaces"])
    cmd.execute!
  end
end
