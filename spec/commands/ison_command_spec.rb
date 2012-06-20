require 'spec_helper'

describe IsonCommand do
  it "should return nickserv if not authenticated" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    irc_connection.should_receive(:send_reply).with(/303 Otto :nickserv/)

    cmd = IsonCommand.new(irc_connection)
    cmd.set_data(["nickserv"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return no such nick if authenticated" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    irc_connection.should_receive(:send_reply).with(/406 Otto nickserv :No such nick\/channel/)

    cmd = WhowasCommand.new(irc_connection)
    cmd.set_data(["nickserv"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
