# http://haproxy.1wt.eu/download/1.5/doc/proxy-protocol.txt
class ProxyCommand < Command
  register_command :PROXY
  def set_data(args)
    @source_ip = args[1]
    @source_port = args[3]
  end

  def valid?
    IrcServer::EXPECT_PROXY_PROTOCOL && @source_ip && @source_port && !irc_connection.client_ip && !irc_connection.client_port && !registered?
  end

  def execute!
    $logger.info "Connection forwarded for #{@source_ip}:#{@source_port}"
    irc_connection.client_ip = @source_ip
    irc_connection.client_port = @source_port
  end
end
