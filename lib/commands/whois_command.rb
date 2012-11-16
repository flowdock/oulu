class WhoisCommand < Command
  register_command :WHOIS

  def set_data(args)
    @nick = args.first
    @nick.downcase! if @nick
  end

  def valid?
    !!@nick and registered?
  end

  def execute!
    reply = if @nick == "nickserv"
      render_whois("NickServ", IrcServer::NICKSERV_EMAIL, IrcServer::NICKSERV_NAME, 0, IrcServer::CREATED_AT)
    elsif @nick == user_nick.downcase # myself, this works even before authentication
      render_whois(user_nick, user_email, user_real_name, 0, IrcServer::CREATED_AT)
    elsif user = find_user(@nick)
      render_whois(user.nick, user.email, user.name, user.idle_time, IrcServer::CREATED_AT)
    else
      render_no_such_nick(@nick)
    end

    send_reply(reply)
  end
end
