class TwitterEvent < FlowdockEvent
  register_event "twitter"

  def render
    rss_text = team_inbox_event("Twitter", "#{@message['content']['user']['screen_name']}: #{@message['content']['text']}")
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, rss_text)
  end

  def valid?
    channel?
  end
end
