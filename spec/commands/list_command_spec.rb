require 'spec_helper'

describe ListCommand do
  it "should list all channels without arguments" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    channels = [example_irc_channel(irc_connection, 0), example_irc_channel(irc_connection, 1)]
    irc_connection.should_receive(:channels).and_return({ 'irc/ottotest' => channels[0], 'irc/ottotest2' => channels[1]})
    irc_connection.should_receive(:send_reply).with(/#irc\/ottotest.*#irc\/ottotest2.*End of LIST/m)

    cmd = ListCommand.new(irc_connection)
    cmd.set_data([])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should list a specific channels with arguments" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection, 1)
    irc_connection.should_receive(:find_channel_by_name).with('#irc/ottotest2').and_return(channel)
    irc_connection.should_not_receive(:send_reply).with(/Otto #irc\/ottotest :/m)
    irc_connection.should_receive(:send_reply).with(/#irc\/ottotest2.*End of LIST/m)

    cmd = ListCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest2"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return just empty list if not authenticated" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    irc_connection.should_receive(:send_reply).with(/End of LIST/)

    cmd = ListCommand.new(irc_connection)
    cmd.set_data([])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should skip channels that do not exist" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    irc_connection.should_receive(:find_channel_by_name).with('#irc/ottotest').and_return(channel)
    irc_connection.should_receive(:find_channel_by_name).with('#foo').and_return(nil)
    irc_connection.should_not_receive(:send_reply).with(/#foo/m)
    irc_connection.should_receive(:send_reply).with(/#irc\/ottotest.*End of LIST/m)

    cmd = ListCommand.new(irc_connection)
    cmd.set_data(["#irc/ottotest,#foo"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not be valid before registration" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => false)

    cmd = ListCommand.new(irc_connection)
    cmd.set_data([])
    cmd.valid?.should be_false
  end
end
