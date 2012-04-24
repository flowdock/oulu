class RssEvent < FlowdockEvent
  register_event "rss"

  def render
    rss_text = team_inbox_event("RSS", "[#{@message['content']['feed']['title']}]: #{@message['content']['title']}")
    render_notice(IrcServer::FLOWDOCK_USER, @channel.irc_id, rss_text)
  end
end
