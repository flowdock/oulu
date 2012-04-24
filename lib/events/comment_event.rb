class CommentEvent < FlowdockEvent
  register_event "comment"

  def process
    text = render_privmsg(@user.irc_host, @channel.irc_id, "[#{@message['content']['title']}] << #{@message['content']['text']}")
    @irc_connection.send_reply(text)
  end
end