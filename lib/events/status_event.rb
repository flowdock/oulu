class StatusEvent < FlowdockEvent
  register_event "status"
  register_event "line"

  def render
    if @message['event'] == 'status'
      render_status(@user.irc_host, @channel.irc_id, @message['content'])
    elsif @message['event'] == 'line'
      render_line(@user.irc_host, @channel.irc_id, @message['content'])
    end
  end
end
