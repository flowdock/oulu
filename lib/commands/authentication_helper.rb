module AuthenticationHelper

  # This will do an async HTTP call.
  def authentication_send(email, password)
    old_irc_host = user_irc_host

    irc_connection.authenticate(email, password) do |error, error_message|
      yield if block_given?
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
      render_topic(channel.irc_id, channel.topic),
      render_names_nicks(channel.irc_id, channel.users.map(&:nick)),
      render_names_end(channel.irc_id)]
    end.flatten

    send_replies([nick_change] + joins)
  end

  def registration_done
    replies = [render_welcome, render_yourhost, render_created, motd_lines]
    if irc_connection.email && irc_connection.password
      # When PASS authenticating, we should wait for the authentication to
      # complete before completing the registration as a reconnecting client
      # will send the JOINs immediately after that and we don't want to return
      # no such channel errors if authentication is still ongoing.
      authentication_send(irc_connection.email, irc_connection.password) do
        send_replies(replies)
      end
    else
      replies << nickserv_auth_notice
      send_replies(replies)
    end
  end

  def nickserv_auth_notice
    render_notice(IrcServer::NICKSERV_HOST, user_nick, "Please identify via /msg NickServ identify <email> <password>")
  end

  def motd_send
    send_replies(motd_lines)
  end

  private

  def motd_lines
    replies = [ render_motd_start ]
    File.open(IrcServer::MOTD_FILE, &:readlines).each do |line|
      replies << render_motd_line(line)
    end
    replies << render_motd_end
  rescue
    [render_motd_start, render_motd_end]
  end
end
