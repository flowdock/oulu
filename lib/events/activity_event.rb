class ActivityEvent < FlowdockEvent
  register_event "activity"

  def render
    author = @message["author"]["name"]
    thread = @message["thread"]
    title = @message["title"]

    text = thread_event(author, thread, title)
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, text)
  end

  def valid?
    channel?
  end
end
