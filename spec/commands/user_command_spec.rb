require 'spec_helper'

describe UserCommand do
  it "shouldn't be valid if user is already authenticated" do
    irc_connection = mock(:irc_connection, :authenticated? => true)

    cmd = UserCommand.new(irc_connection)
    cmd.set_data(["otto", "foo", "bar", "Otto Hilska"])
    cmd.valid?.should be_false
  end

  it "should configure email and real name, and send a PING" do
    irc_connection = mock(:irc_connection, :authenticated? => false)
    irc_connection.should_receive(:email=).with("otto@unknown")
    irc_connection.should_receive(:real_name=).with("Otto Hilska")
    irc_connection.should_receive(:last_ping_sent=).with(/FLOWDOCK-/)
    irc_connection.should_receive(:send_reply).with(/PING/)

    cmd = UserCommand.new(irc_connection)
    cmd.set_data(["otto", "foo", "bar", "Otto Hilska"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
