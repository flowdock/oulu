class CommentEvent < FlowdockEvent
  register_event "comment"

  def render
    render_privmsg(@user.irc_host, @target.irc_id, "[#{@message['content']['title']}] << #{@message['content']['text']}")
  end

  def valid?
    channel?
  end
end
