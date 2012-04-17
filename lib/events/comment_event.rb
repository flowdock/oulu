class CommentEvent < FlowdockEvent
  register_event "comment"

  def valid?
    !@message['content'].nil? && !@message['content']['text'].nil?
  end

  def process
    text = cmd.send(:render_privmsg, @user.irc_host, @channel.irc_id, "[#{@message['content']['title']}] << #{@message['content']['text']}")
    @irc_connection.send_reply(text)
  end
end