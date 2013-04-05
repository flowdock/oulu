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
    replies = if @nick == "nickserv"
      render_whois("NickServ", IrcServer::NICKSERV_EMAIL, IrcServer::NICKSERV_NAME, 0)
    elsif @nick == user_nick.downcase # myself, this works even before authentication
      channels = irc_connection.channels.values.select(&:open?).map(&:irc_id).join(" ") if authenticated? && irc_connection.channels
      render_whois(user_nick, user_email, user_real_name, 0, channels)
    elsif authenticated? && user = find_user(@nick)
      channels = irc_connection.channels.values.select{|c| c.users.map(&:id).include?(user.id)}.map(&:irc_id).join(" ")
      render_whois(user.nick, user.email, user.name, user.idle_time, channels)
    else
      [render_no_such_nick(@nick)]
    end
    send_replies(replies)
  end

  def render_whois(nick, email, realname, idle_time, channel_list=nil)
    replies = [ render_whois_user(nick, email, realname) ]
    replies << render_whois_channels(nick, channel_list) if channel_list
    replies << render_whois_server(nick)
    replies << render_whois_idle(nick, idle_time, IrcServer::CREATED_AT)
    replies << render_whois_end(nick)
  end
end
