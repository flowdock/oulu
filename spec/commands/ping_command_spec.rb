require 'spec_helper'

describe PingCommand do
  it "should reply with the same value when authenticated" do
    irc_connection = double(:irc_connection, :authenticated? => true)
    expect(irc_connection).to receive(:send_reply).with(/PONG/)
    cmd = PingCommand.new(irc_connection)
    cmd.set_data(["FOO"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should reply with the same value when not authenticated" do
    irc_connection = double(:irc_connection, :authenticated? => false)
    expect(irc_connection).to receive(:send_reply).with(/PONG/)
    cmd = PingCommand.new(irc_connection)
    cmd.set_data(["FOO"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should not be valid when the parameter is missing" do
    irc_connection = double(:irc_connection, :authenticated? => true)
    cmd = PingCommand.new(irc_connection)
    cmd.set_data([])
    expect(cmd).not_to be_valid
  end
end
