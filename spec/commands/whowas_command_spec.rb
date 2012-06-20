require 'spec_helper'

describe WhowasCommand do
  it "should always render no such nick" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true)
    irc_connection.should_receive(:send_reply).with(/406 Otto otto :No such nick\/channel/)

    cmd = WhowasCommand.new(irc_connection)
    cmd.set_data(["Otto"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
