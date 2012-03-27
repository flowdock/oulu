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
      # Also an async HTTP call.
      irc_connection.post_message(channel.flowdock_id, @message)
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

      irc_connection.authenticate(email, password) do
        if authenticated?
          authentication_done(old_irc_host)
        else
          # Ignore error for now
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
