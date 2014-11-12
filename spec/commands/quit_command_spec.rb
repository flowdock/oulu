require 'spec_helper'

describe QuitCommand do
  it "should send reply and call IRC connection's quit!" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :email => 'otto@example.com')
    expect(irc_connection).to receive(:quit!)
    expect(irc_connection).to receive(:send_reply).with(/Closing Link/)

    cmd = QuitCommand.new(irc_connection)
    cmd.set_data([])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
