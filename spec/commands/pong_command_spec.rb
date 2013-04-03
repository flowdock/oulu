require 'spec_helper'

describe "PongCommand" do
  it "should update last pong received at" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :last_ping_sent => "FOOBAR")
    irc_connection.should_receive(:last_pong_received_at=)
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
end
