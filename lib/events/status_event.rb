class StatusEvent < FlowdockEvent
  register_event "status"
  register_event "line"

  def process
    text = cmd.send(:"render_#{@message['event']}", @user.irc_host, @channel.irc_id, @message['content'])
    @irc_connection.send_reply(text)
  end
end
