class StatusEvent < FlowdockEvent
  register_event "status"
  register_event "line"

  def process
    if !@irc_connection.remove_outgoing_message(@message) # don't render own /me messages twice
      text = self.render
      @irc_connection.send_reply(text)
    end
  end

  def render
    if @message['event'] == 'status'
      render_status(@user.irc_host, @channel.irc_id, @message['content'])
    elsif @message['event'] == 'line'
      render_line(@user.irc_host, @channel.irc_id, @message['content'])
    end
  end
end
