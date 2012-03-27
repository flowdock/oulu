class WhoisCommand < Command
  register_command :WHOIS

  def set_data(args)
    @nick = args.first
    @nick.downcase! if @nick
  end

  def valid?
    !!@nick
  end

  def execute!
    reply = if @nick == "nickserv"
      render_whois("NickServ", IrcServer::NICKSERV_HOST, IrcServer::NICKSERV_NAME, 0, Time.now)
    elsif @nick == user_nick.downcase # myself, this works even before authentication
      render_whois(user_nick, user_irc_host, user_real_name, 0, Time.now)
    elsif user = irc_connection.find_user_by_nick(@nick)
      render_whois(user.nick, user.irc_host, user.name, 0, Time.now)
    else
      render_no_such_nick(@nick)
    end

    send_reply(reply)
  end
end
