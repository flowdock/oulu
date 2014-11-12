require 'spec_helper'

describe ProxyCommand do
  it "should upgrade connection info" do
    original_constant = IrcServer::EXPECT_PROXY_PROTOCOL
    reset_constant(IrcServer, "EXPECT_PROXY_PROTOCOL", true)
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => false, :client_ip=>nil, :client_port=>nil)
    expect(irc_connection).to receive(:client_ip=).with("1.2.3.4")
    expect(irc_connection).to receive(:client_port=).with("51190")

    cmd = ProxyCommand.new(irc_connection)
    cmd.set_data(["TCP4", "1.2.3.4", "127.0.0.1", "51190", "6697"])
    expect(cmd).to be_valid
    cmd.execute!
    reset_constant(IrcServer, "EXPECT_PROXY_PROTOCOL", original_constant)
  end

  it "should not be valid if proxy protocol is not expected" do
    original_constant = IrcServer::EXPECT_PROXY_PROTOCOL
    reset_constant(IrcServer, "EXPECT_PROXY_PROTOCOL", false)
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => false, :client_ip=>nil, :client_port=>nil)
    expect(irc_connection).not_to receive(:client_ip=)
    expect(irc_connection).not_to receive(:client_port=)

    cmd = ProxyCommand.new(irc_connection)
    cmd.set_data(["TCP4", "1.2.3.4", "127.0.0.1", "51190", "6697"])
    expect(cmd).not_to be_valid
    reset_constant(IrcServer, "EXPECT_PROXY_PROTOCOL", original_constant)
  end

  it "should be valid only before ip/port has been set" do
    irc_connection = double(:irc_connection, :nick => 'Otto', :registered? => false, :client_ip=> "1.1.2.2", :client_port => "1234")
    cmd = ProxyCommand.new(irc_connection)
    cmd.set_data(["TCP4", "1.2.3.4", "127.0.0.1", "51190", "6697"])
    expect(cmd).not_to be_valid
  end
end
