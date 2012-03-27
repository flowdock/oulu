require 'spec_helper'

describe QuitCommand do
  it "should send reply and call IRC connection's quit!" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :email => 'otto@example.com')
    irc_connection.should_receive(:quit!)
    irc_connection.should_receive(:send_reply).with(/Closing Link/)

    cmd = QuitCommand.new(irc_connection)
    cmd.set_data([])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
