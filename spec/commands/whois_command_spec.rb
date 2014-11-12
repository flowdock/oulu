require 'spec_helper'

describe WhoisCommand do
  it "should always recognize NickServ" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => true, :authenticated? => false)
    expect(irc_connection).to receive(:send_reply).with(/Nickname Services/) # real name is present

    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data(["nickserv"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should always recognize myself" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :real_name => 'Otto Hilska',
      :email => 'otto@example.com', :registered? => true, :authenticated? => false)
    expect(irc_connection).to receive(:send_reply).with(/Otto Hilska/)

    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data(["otto"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should find users from my channels" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :real_name => 'Otto Hilska',
      :email => 'otto@example.com', :registered? => true, :authenticated? => true)
    channel = example_irc_channel(irc_connection)
    user = channel.users[1]
    expect(user).to receive(:idle_time)
    expect(irc_connection).to receive(:channels).and_return({'irc/ottotest' => channel})
    expect(irc_connection).to receive(:find_user_by_nick).with('ottomob').and_return(user)
    expect(irc_connection).to receive(:send_reply).with(/Ottomob Heelskae.*#irc\/ottotest.*:seconds idle.*End of WHOIS/m)

    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data(["ottomob"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should not find users who are not on my channels" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :real_name => 'Otto Hilska',
      :email => 'otto@example.com', :registered? => true, :authenticated? => true)

    expect(irc_connection).to receive(:find_user_by_nick).with('ottofoo').and_return(nil)
    expect(irc_connection).to receive(:send_reply).with(/No such nick/)

    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data(["ottofoo"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should be invalid without arguments" do
    irc_connection = double(:irc_connection, :registered? => true, :authenticated? => true)
    cmd = WhoisCommand.new(irc_connection)
    cmd.set_data([])
    expect(cmd).not_to be_valid
  end
end
