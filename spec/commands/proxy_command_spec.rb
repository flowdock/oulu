require 'spec_helper'

describe ProxyCommand do
  it "should upgrade connection info" do
    original_constant = IrcServer::EXPECT_PROXY_PROTOCOL
    reset_constant(IrcServer, "EXPECT_PROXY_PROTOCOL", true)
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => false, :client_ip=>nil, :client_port=>nil)
    irc_connection.should_receive(:client_ip=).with("1.2.3.4")
    irc_connection.should_receive(:client_port=).with("51190")

    cmd = ProxyCommand.new(irc_connection)
    cmd.set_data(["TCP4", "1.2.3.4", "127.0.0.1", "51190", "6697"])
    cmd.valid?.should be_true
    cmd.execute!
    reset_constant(IrcServer, "EXPECT_PROXY_PROTOCOL", original_constant)
  end

  it "should not be valid if proxy protocol is not expected" do
    original_constant = IrcServer::EXPECT_PROXY_PROTOCOL
    reset_constant(IrcServer, "EXPECT_PROXY_PROTOCOL", false)
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => false, :client_ip=>nil, :client_port=>nil)
    irc_connection.should_not_receive(:client_ip=)
    irc_connection.should_not_receive(:client_port=)

    cmd = ProxyCommand.new(irc_connection)
    cmd.set_data(["TCP4", "1.2.3.4", "127.0.0.1", "51190", "6697"])
    cmd.valid?.should be_false
    reset_constant(IrcServer, "EXPECT_PROXY_PROTOCOL", original_constant)
  end

  it "should be valid only before ip/port has been set" do
    irc_connection = mock(:irc_connection, :nick => 'Otto', :registered? => false, :client_ip=> "1.1.2.2", :client_port => "1234")
    cmd = ProxyCommand.new(irc_connection)
    cmd.set_data(["TCP4", "1.2.3.4", "127.0.0.1", "51190", "6697"])
    cmd.valid?.should be_false
  end
end
