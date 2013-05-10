class FlowAddEvent < FlowdockEvent
  register_event "flow-add"

  def process
    return if @user.id != @irc_connection.user_id
    @irc_connection.add_channel(@message['content'])
  end

  def valid?
    !!@user && @message['content'] && !!@message['content']['id']
  end
end
