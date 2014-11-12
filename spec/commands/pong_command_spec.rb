require 'spec_helper'

describe "PongCommand" do
  it "should update last pong received at" do
    irc_connection = double(:irc_connection, :authenticated? => true, :last_ping_sent => "FOOBAR")
    expect(irc_connection).to receive(:last_pong_received_at=)
    expect(irc_connection).not_to receive(:send_reply)
    cmd = PongCommand.new(irc_connection)
    cmd.set_data(["FOOBAR"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should not be valid when PONG doesn't match to last sent PING" do
    irc_connection = double(:irc_connection, :authenticated? => true, :last_ping_sent => "FOOBAR")
    expect(irc_connection).not_to receive(:send_reply)
    cmd = PongCommand.new(irc_connection)
    cmd.set_data(["BARFOO"])
    expect(cmd).not_to be_valid
  end
end
