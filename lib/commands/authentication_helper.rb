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

  def registration_done
    send_replies([render_welcome, render_yourhost, render_created])
    motd_send
    if irc_connection.email && irc_connection.password
      authentication_send(irc_connection.email, irc_connection.password)
    else
      send_reply(nickserv_auth_notice)
    end
  end

  def nickserv_auth_notice
    render_notice(IrcServer::NICKSERV_HOST, user_nick, "Please identify via /msg NickServ identify <email> <password>")
  end

  def motd_send
    replies = [ render_motd_start ]
    motd_data.each do |line|
      replies << render_motd_line(line)
    end
    replies << render_motd_end
    send_replies(replies)
  end

  private

  def motd_data
    File.open(IrcServer::MOTD_FILE, &:readlines)
  rescue
    []
  end

end
