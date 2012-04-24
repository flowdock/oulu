class RssEvent < FlowdockEvent
  register_event "rss"

  def process
    rss_text = team_inbox_event("RSS", "[#{@message['content']['feed']['title']}]: #{@message['content']['title']}")
    text = render_notice(IrcServer::FLOWDOCK_USER, @channel.irc_id, rss_text)
    @irc_connection.send_reply(text)
  end
end
