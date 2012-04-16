class MessageEvent < FlowdockEvent
  register_event "message"

  def valid?
    @message['content'].is_a?(String)
  end

  def process
    if !@irc_connection.remove_outgoing_message(@message) # don't render own messages twice
      $logger.debug "Chat message to #{@channel.flowdock_id}"
      text = cmd.send(:render_privmsg, @user.irc_host, @channel.irc_id, @message['content'])
      @irc_connection.send_reply(text)
    end
  end
end