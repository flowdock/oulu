module AuthenticationHelper

  def authentication_send(email, password)
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