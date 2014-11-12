require 'spec_helper'

describe UserCommand do
  it "should disconnect user if username is invalid" do
    irc_connection = double(:irc_connection, :authenticated? => false, :nick => "otto", :email => nil, :registered? => false)
    expect(irc_connection).not_to receive(:email=)
    expect(irc_connection).to receive(:send_reply).with(/ERROR :Closing Link:/)
    expect(irc_connection).not_to receive(:send_reply).with(/PING/)
    expect(irc_connection).to receive(:quit!)

    cmd = UserCommand.new(irc_connection)
    cmd.set_data(["ot to", "foo", "bar", "Otto Hilska"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "shouldn't be valid if user is already registered" do
    irc_connection = double(:irc_connection, :authenticated? => false, :nick => "otto", :registered? => true)

    cmd = UserCommand.new(irc_connection)
    cmd.set_data(["otto", "foo", "bar", "Otto Hilska"])
    expect(cmd).not_to be_valid
  end

  it "should configure email and real name, and send a PING" do
    irc_connection = double(:irc_connection, :authenticated? => false, :nick => "otto", :registered? => false, :last_ping_sent => nil)
    expect(irc_connection).to receive(:email=).with("otto@unknown")
    expect(irc_connection).to receive(:email).exactly(3).times
    expect(irc_connection).to receive(:real_name=).with("Otto Hilska")
    expect(irc_connection).not_to receive(:authentication_send)
    expect(irc_connection).to receive(:send_reply).with(/Welcome to the Internet Relay Network.*Message of the day.*End of MOTD/m)
    expect(irc_connection).to receive(:ping!)
    expect(irc_connection).to receive(:registered?).exactly(2).times.and_return(false, true)

    cmd = UserCommand.new(irc_connection)
    cmd.set_data(["otto", "foo", "bar", "Otto Hilska"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should start PASS authentication" do
    irc_connection = double(:irc_connection, :authenticated? => false, :registered? => false, :last_ping_sent => nil, :nick => "Otto", :email => "otto@example.com", :password => "password")

    expect(irc_connection).to receive(:real_name=).with("Otto Hilska")
    expect(irc_connection).not_to receive(:email=)
    expect(irc_connection).to receive(:registered?).exactly(2).times.and_return(false, true)
    expect(irc_connection).to receive(:send_reply).with(/Welcome to the Internet Relay Network.*Message of the day.*End of MOTD/m)
    expect(irc_connection).not_to receive(:send_reply).with(/NickServ.*identify/m)
    expect(irc_connection).to receive(:ping!)

    cmd = UserCommand.new(irc_connection)
    expect(cmd).to receive(:authentication_send).with("otto@example.com", "password").and_yield
    cmd.set_data(["otto", "foo", "bar", "Otto Hilska"])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
