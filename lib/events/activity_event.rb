class ActivityEvent < FlowdockEvent
  register_event "activity"

  def render
    source = @message["thread"]["source"]["name"]
    app = @message["thread"]["source"]["application"]["name"]
    thread_title = @message["thread"]["title"]
    title = @message["title"]

    text = thread_event(
      app,
      source,
      thread_title,
      title
    )

    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, text)
  end

  def valid?
    channel?
  end
end
