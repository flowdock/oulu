class FileEvent < FlowdockEvent
  register_event "file"

  def valid?
    !@message['content'].nil?
  end

  def process
    (organization, flow) = @channel.flowdock_id.split('/')
    url = "https://#{organization}.#{IrcServer::FLOWDOCK_DOMAIN}#{@message['content']['path']}"
    text = cmd.send(:render_privmsg, @user.irc_host, @channel.irc_id, url)
    @irc_connection.send_reply(text)
  end
end