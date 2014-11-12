require 'spec_helper'

describe WhowasCommand do
  it "should always render no such nick" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true)
    expect(irc_connection).to receive(:send_reply).with(/406 Otto otto :No such nick\/channel/)

    cmd = WhowasCommand.new(irc_connection)
    cmd.set_data(["Otto"])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
