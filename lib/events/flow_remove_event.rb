class FlowRemoveEvent < FlowdockEvent
  register_event "flow-remove"

  def process
    return if @user.id != @irc_connection.user_id

    channel = @irc_connection.find_channel_by_id(@message['content']['id'])
    if channel
      @irc_connection.remove_channel(channel)     
      @irc_connection.send_reply(render_user_part(@user.irc_host, channel.irc_id)) if channel.open?
    end
  end

  def valid?
    !!@user && !!@message['content']['id']
  end
end
