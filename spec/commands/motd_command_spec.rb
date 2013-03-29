require 'spec_helper'

describe "MotdCommand" do
  it "should output motd" do
    irc_connection = mock(:irc_connection, :authenticated? => true, :registered? => true, :nick => "otto", :last_ping_sent => "FOOBAR")
    irc_connection.should_receive(:send_reply).with(/ 375 otto :- #{IrcServer::HOST} Message of the day.* 372 otto :-.* 376 otto :End of MOTD command/m)

    cmd = MotdCommand.new(irc_connection)
    cmd.valid?.should be_true
    cmd.execute!
  end
end
