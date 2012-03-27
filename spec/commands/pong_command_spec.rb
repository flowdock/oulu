require 'spec_helper'

describe "PongCommand" do
  it "should not output anything for authenticated users" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :last_ping_sent => "FOOBAR")
    irc_connection.should_not_receive(:send_reply)
    cmd = PongCommand.new(irc_connection)
    cmd.set_data(["FOOBAR"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not be valid when PONG doesn't match to last sent PING" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :last_ping_sent => "FOOBAR")
    irc_connection.should_not_receive(:send_reply)
    cmd = PongCommand.new(irc_connection)
    cmd.set_data(["BARFOO"])
    cmd.valid?.should be_false
  end

  it "should output MOTD for non-authenticated users" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :last_ping_sent => "FOOBAR", :nick => "Otto", :email => "otto@example.com")

    # It should reply with something about MOTD and identifying with NickServ.
    irc_connection.should_receive(:send_reply).with(/End of MOTD.*NickServ.*identify/m)
    cmd = PongCommand.new(irc_connection)
    cmd.set_data(["FOOBAR"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
