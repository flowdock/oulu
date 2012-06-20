require 'spec_helper'

describe WhoCommand do
  it "should display users and End Of WHO when channel is found" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true)
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:find_channel).with("#irc/ottotest").and_return(channel)
    irc_connection.should_receive(:send_reply).with(/example.com.*Ottomob.*End of WHO list/m)

    cmd = WhoCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should just display End of WHO when channel is not found" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true)
    irc_connection.should_receive(:find_channel).with("*.fi").and_return(nil)
    irc_connection.should_receive(:send_reply).with(/\*\.fi.*End of WHO list/)

    cmd = WhoCommand.new(irc_connection)
    cmd.set_data(["*.fi"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
