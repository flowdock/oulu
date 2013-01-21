class MessageEditEvent < FlowdockEvent
  register_event "message-edit"

  def process
    text = render_privmsg(@user.irc_host, @target.irc_id, @message['content']['updated_content'] + "*")
    @irc_connection.send_reply(text)
  end

  def valid?
    true
  end
end

