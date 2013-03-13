class FileEvent < FlowdockEvent
  register_event "file"

  def render
    (organization, flow) = @target.visible_name.split('/')
    url = "https://#{organization}.#{IrcServer::FLOWDOCK_DOMAIN}#{@message['content']['path']}"
    render_privmsg(@user.irc_host, @target.irc_id, url)
  end

  def valid?
    channel?
  end
end
