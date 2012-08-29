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
    irc_host = if @user
      @user.irc_host
    elsif @message['external_user_name']
      irc_host = "#{message['external_user_name']}!#{IrcServer::UNKNOWN_USER_EMAIL}"
    end

    render_privmsg(irc_host, @channel.irc_id, @message['content'])
  end
end
