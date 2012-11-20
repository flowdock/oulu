require 'spec_helper'

describe IsonCommand do
  it "should return nickserv if not authenticated" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    irc_connection.should_receive(:send_reply).with(/303 Otto :NickServ$/)

    cmd = IsonCommand.new(irc_connection)
    cmd.set_data(["nickserv"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return empty list for nickserv if authenticated" do
    user = mock(:user, :id => 1, :nick => "SomeOne")
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    irc_connection.should_receive(:unique_users).and_return([user])
    irc_connection.should_receive(:send_reply).with(/303 Otto :$/)

    cmd = IsonCommand.new(irc_connection)
    cmd.set_data(["nickserv"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should return requested available users if authenticated" do
    users = [mock(:user, :id => 1, :nick => "SomeOne"), mock(:user, :id => 2, :nick => "SomeOther"), mock(:user, :id => 3, :nick => "Third")]
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => true)
    irc_connection.should_receive(:unique_users).and_return(users)
    irc_connection.should_receive(:send_reply).with(/303 Otto :SomeOne SomeOther/)

    cmd = IsonCommand.new(irc_connection)
    cmd.set_data(["SomeOne", "Nobody", "SomeOther"])
    cmd.valid?.should be_true
    cmd.execute!
  end
end
