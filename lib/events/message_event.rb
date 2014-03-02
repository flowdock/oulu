class MessageEvent < FlowdockEvent
  register_event "message"
  INVALID_NICK_CHARS = /[^a-zA-Z0-9\[\]`_\-\^{\|}]/

  def process
    return if user? && @user.id == @irc_connection.user_id # don't render own private messages sent in other sessions

    if !@irc_connection.remove_outgoing_message(@message) # don't render own messages twice
      $logger.debug "Chat message to #{@target.irc_id}"
      text = self.render
      @irc_connection.send_reply(text)
    end
  end

  def render
    irc_host = if @user
      @user.irc_host
    elsif @message['external_user_name']
      nick = @message['external_user_name'].gsub(INVALID_NICK_CHARS, '_')
      "#{nick}!#{IrcServer::UNKNOWN_USER_EMAIL}"
    end

    content = process_content @message['content']

    render_privmsg(irc_host, @target.irc_id, content)
  end

  def valid?
    !!@target
  end

  require 'gemoji'
  def process_content content
    content.split('').map do |ch|
      em = Emoji.name_for ch
      STDOUT << "#{ch.inspect} -> #{em.inspect}" if ch !~ /A-Za-z0-9/
      em ? ":#{em}:" : ch
    end.join('')
  end
end
