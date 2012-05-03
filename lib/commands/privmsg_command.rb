class PrivmsgCommand < Command
  register_command :PRIVMSG

  def set_data(args)
    if args.size == 2
      @target = args.first
      @message = args.last
    end
  end

  def valid?
    !!@target && !!@message
  end

  def execute!
    if !authenticated? && @target.downcase == 'nickserv'
      handle_nickserv!
    elsif channel = find_channel(@target)
      # match to /me command which is actually a PRIVMSG with special format
      if m = @message.match(/^\u0001ACTION (.+)\u0001$/)
        irc_connection.post_status_message(channel.flowdock_id, m[1])
      else
        irc_connection.post_chat_message(channel.flowdock_id, @message)
      end
    else
      send_reply(render_no_such_nick(@target))
    end
  end

  protected

  def handle_nickserv!
    keyword, email, password = @message.split(' ')

    if keyword.downcase == 'identify' && email && password
      # This will do an async HTTP call.
      old_irc_host = user_irc_host

      irc_connection.authenticate(email, password) do |error, error_message|
        if authenticated? && !error
          authentication_done(old_irc_host)
        else
          send_reply(render_notice(IrcServer::NICKSERV_HOST, user_nick, error_message))
        end
      end
    end
  end

  def authentication_done(old_irc_host)
    nick_change = render_nick(old_irc_host, user_nick)

    joins = irc_connection.channels.values.map do |channel|
      [render_join(channel.irc_id),
       render_names_nicks(channel.irc_id, channel.users.map(&:nick)),
       render_names_end(channel.irc_id)]
    end.flatten

    send_replies([nick_change] + joins)
  end
end
