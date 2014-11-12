require 'spec_helper'

describe IsonCommand do
  it "should return nickserv if not authenticated" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    expect(irc_connection).to receive(:send_reply).with(/303 Otto :NickServ$/)

    cmd = IsonCommand.new(irc_connection)
    cmd.set_data(["nickserv"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should return empty list for nickserv if authenticated" do
    user = double(:user, :id => 1, :nick => "SomeOne")
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    expect(irc_connection).to receive(:unique_users).and_return([user])
    expect(irc_connection).to receive(:send_reply).with(/303 Otto :$/)

    cmd = IsonCommand.new(irc_connection)
    cmd.set_data(["nickserv"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should return requested available users if authenticated" do
    users = [double(:user, :id => 1, :nick => "SomeOne"), double(:user, :id => 2, :nick => "SomeOther"), double(:user, :id => 3, :nick => "Third")]
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    expect(irc_connection).to receive(:unique_users).and_return(users)
    expect(irc_connection).to receive(:send_reply).with(/303 Otto :SomeOne SomeOther/)

    cmd = IsonCommand.new(irc_connection)
    cmd.set_data(["SomeOne", "Nobody", "SomeOther"])
    expect(cmd).to be_valid
    cmd.execute!
  end
end
