require 'spec_helper'

describe WhoisCommand do
  it "should always recognize NickServ" do
    irc_connection = mock(:irc_connection, :nick => 'Otto')
    irc_connection.should_receive(:send_reply).with(/Nickname Services/) # real name is present

    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data(["nickserv"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should always recognize myself" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :real_name => 'Otto Hilska',
      :email => 'otto@example.com')
    irc_connection.should_receive(:send_reply).with(/Otto Hilska/)

    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data(["otto"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should find users from my channels" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :real_name => 'Otto Hilska',
      :email => 'otto@example.com')
    user = mock(:user, :nick => 'Ottomob', :email => 'ottomob@example.com', :name => 'Mobile User', :irc_host => 'Ottomob!ottomob@example.com')

    irc_connection.should_receive(:find_user_by_nick).with('ottomob').and_return(user)
    irc_connection.should_receive(:send_reply).with(/Mobile User/)

    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data(["ottomob"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should not find users who are not on my channels" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :real_name => 'Otto Hilska',
      :email => 'otto@example.com')

    irc_connection.should_receive(:find_user_by_nick).with('ottofoo').and_return(nil)
    irc_connection.should_receive(:send_reply).with(/No such nick/)

    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data(["ottofoo"])
    cmd.valid?.should be_true
    cmd.execute!
  end

  it "should be invalid without arguments" do
    irc_connection = mock(:irc_connection)
    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data([])
    cmd.valid?.should be_false
  end
end
