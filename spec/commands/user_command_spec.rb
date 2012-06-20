require 'spec_helper'

describe UserCommand do
  it "should disconnect user if username is invalid" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :nick => "otto", :email => nil, :registered? => false)
    irc_connection.should_not_receive(:email=)
    irc_connection.should_receive(:send_reply).with(/ERROR :Closing Link:/)
    irc_connection.should_not_receive(:send_reply).with(/PING/)
    irc_connection.should_receive(:quit!)

    cmd = UserCommand.new(irc_connection)
    cmd.set_data(["ot to", "foo", "bar", "Otto Hilska"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "shouldn't be valid if user is already registered" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :nick => "otto", :registered? => true)

    cmd = UserCommand.new(irc_connection)
    cmd.set_data(["otto", "foo", "bar", "Otto Hilska"])
    cmd.valid?.should be_false
  end

  it "should configure email and real name, and send a PING" do
    irc_connection = mock(:irc_connection, :authenticated? => false, :nick => "otto", :registered? => false, :last_ping_sent => nil)
    irc_connection.should_receive(:email=).with("otto@unknown")
    irc_connection.should_receive(:real_name=).with("Otto Hilska")
    irc_connection.should_receive(:ping!)
    irc_connection.should_receive(:registered?).exactly(2).times.and_return(false, true)

    cmd = UserCommand.new(irc_connection)
    cmd.set_data(["otto", "foo", "bar", "Otto Hilska"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
