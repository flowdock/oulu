class FileEvent < FlowdockEvent
  register_event "file"

  def process
    return if user? && @user.id == @irc_connection.user_id # don't render own private messages sent in other sessions
    super
  end

  def render
    url = "https://www.#{IrcServer::FLOWDOCK_DOMAIN}/rest#{@message['content']['path']}"
    render_privmsg(@user.irc_host, @target.irc_id, url)
  end

  def valid?
    !!@target
  end
end
