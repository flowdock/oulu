class MessageEvent < FlowdockEvent
  register_event "message"

  def process
    if !@irc_connection.remove_outgoing_message(@message) # don't render own messages twice
      $logger.debug "Chat message to #{@channel.flowdock_id}"
      text = self.render
      @irc_connection.send_reply(text)
    end
  end

  def render
    render_privmsg(@user.irc_host, @channel.irc_id, @message['content'])
  end
end
