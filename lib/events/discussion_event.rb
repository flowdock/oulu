class DiscussionEvent < FlowdockEvent
  register_event "discussion"

  def render
    author = @message["author"]["name"]
    thread = @message["thread"]
    title = strip_html(@message["title"])

    text = thread_event(author, thread, title)
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, text)
  end

  def valid?
    channel?
  end
end
