require 'spec_helper'

describe WhoCommand do
  it "should display users and End Of WHO when channel is found" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true)
    channel = example_irc_channel(irc_connection)
    expect(irc_connection).to receive(:find_channel_by_name).with("#irc/ottotest").and_return(channel)
    expect(irc_connection).to receive(:send_reply).with(/example.com.*Ottomob.*End of WHO list/m)

    cmd = WhoCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should just display End of WHO when channel is not found" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true)
    expect(irc_connection).to receive(:find_channel_by_name).with("*.fi").and_return(nil)
    expect(irc_connection).to receive(:send_reply).with(/\*\.fi.*End of WHO list/)

    cmd = WhoCommand.new(irc_connection)
    cmd.set_data(["*.fi"])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
