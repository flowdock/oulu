require 'spec_helper'

describe PingCommand do
  it "should reply with the same value when authenticated" do
    irc_connection = mock(:irc_connection, :authenticated? => true)
    irc_connection.should_receive(:send_reply).with(/PONG/)
    cmd = PingCommand.new(irc_connection)
    cmd.set_data(["FOO"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should reply with the same value when not authenticated" do
    irc_connection = mock(:irc_connection, :authenticated? => false)
    irc_connection.should_receive(:send_reply).with(/PONG/)
    cmd = PingCommand.new(irc_connection)
    cmd.set_data(["FOO"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not be valid when the parameter is missing" do
    irc_connection = mock(:irc_connection, :authenticated? => true)
    cmd = PingCommand.new(irc_connection)
    cmd.set_data([])
    cmd.valid?.should be_false
  end
end
