require 'uri'

class FileEvent < FlowdockEvent
  register_event "file"

  def render
    (organization, flow) = @target.visible_name.split('/')
    url = "https://www.#{IrcServer::FLOWDOCK_DOMAIN}/rest#{URI::encode(@message['content']['path'])}"
    render_privmsg(@user.irc_host, @target.irc_id, url)
  end

  def valid?
    channel?
  end
end
