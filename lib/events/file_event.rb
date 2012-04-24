class FileEvent < FlowdockEvent
  register_event "file"

  def render
    (organization, flow) = @channel.flowdock_id.split('/')
    url = "https://#{organization}.#{IrcServer::FLOWDOCK_DOMAIN}#{@message['content']['path']}"
    render_privmsg(@user.irc_host, @channel.irc_id, url)
  end
end
