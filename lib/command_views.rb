# Render static parameters to IRC protocol strings.
module CommandViews
  def render_notice(sender_host, target, text)
    multi_line(text) do |line|
      ":#{sender_host} NOTICE #{target} :#{line}"
    end
  end

  def render_join(channel)
    ":#{user_irc_host} JOIN :#{channel}"
  end

  def render_user_part(parted_user_irc_host, channel)
    ":#{parted_user_irc_host} PART #{channel}"
  end

  def render_user_join(joined_user_irc_host, channel)
    ":#{joined_user_irc_host} JOIN #{channel}"
  end

  def render_kick(blocker_irc_host, blocked_user_nick, channel)
    ":#{blocker_irc_host} KICK #{channel} #{blocked_user_nick}"
  end

  def render_mode(sender_host, target, mode)
    ":#{sender_host} MODE #{target} :#{mode}"
  end

  def render_end_of_ban_list(channel)
    server_msg("368", channel, "End of Channel Ban List")
  end

  def render_channel_modes(channel, modes)
    server_msg("324", channel, modes.to_s)
  end

  def render_names_nicks(channel, nicks)
    server_msg("353", "@", channel, nicks.join(' '))
  end

  def render_names_end(channel)
    server_msg("366", channel, "End of NAMES list")
  end

  def render_ison(nicks)
    server_msg("303", nicks.join(' '))
  end

  def render_nick(old_host, new_nick)
    ":#{old_host} NICK :#{new_nick}"
  end

  def render_nick_error(new_nick)
    server_msg("432", new_nick, "Erroneous nickname")
  end

  def render_ping(value)
    "PING :#{value}"
  end

  def render_pong(value)
    ":#{IrcServer::HOST} PONG #{IrcServer::HOST} :#{value}"
  end

  def render_privmsg(sender_host, target, text)
    multi_line(text) do |line|
      ":#{sender_host} PRIVMSG #{target} :#{line}"
    end
  end

  def render_line(sender_host, channel, text, extra = '')
    ":#{sender_host} PRIVMSG #{channel} :\u0001ACTION #{extra}#{text}\u0001"
  end

  def render_status(sender_host, channel, text)
    render_line(sender_host, channel, text, "changed status to: ")
  end

  def render_quit(message = "leaving", user_origin = true)
    message = "\"#{message}\"" if user_origin
    "ERROR :Closing Link: #{user_nick}[#{user_email}] (#{message})"
  end

  def render_whois(nick, email, realname, idle_seconds, signon_timestamp)
    [ [311, "#{email_split(email)} * :#{realname}"],
      [312, "#{server_host} :#{IrcServer::NAME}"],
      [317, "#{idle_seconds.to_i} #{signon_timestamp.to_i} :seconds idle, signon time"],
      [318, ":End of WHOIS list."] ].map do |code, text|
        ":#{server_host} #{code} #{user_nick} #{nick} #{text}"
    end.join("\r\n")
  end

  def render_who(channel, nick, email, realname)
    server_msg(352, channel, email_split(email), IrcServer::HOST, nick, 'H', "0 #{realname}")
  end

  def render_who_end(channel)
    server_msg(315, channel, "End of WHO list")
  end

  def render_no_such_nick(nick)
    server_msg(401, nick, "No such nick/channel")
  end

  def render_was_no_such_nick(nick)
    server_msg(406, nick, "No such nick/channel")
  end

  def render_set_away
    server_msg(306, "You have been marked as being away")
  end

  def render_unset_away
    server_msg(305, "You are no longer marked as being away")
  end

  ## MOTD

  def render_welcome
    server_msg("001", "Welcome to the Internet Relay Network #{user_irc_host}")
  end

  def render_yourhost
    server_msg("002", "Your host is #{server_host}, running version 1.0")
  end

  def render_created
    server_msg("003", "This server was created at #{IrcServer::CREATED_AT}")
  end

  def render_motd_start
    server_msg("375", "- #{server_host} Message of the day - ")
  end

  def render_motd_line(text)
    server_msg("372", "- #{text}")
  end

  def render_motd_end
    server_msg("376", "End of MOTD command")
  end

  ## Helpers

  protected

  def multi_line(text, &block)
    text.split("\n").map do |line|
      yield line
    end.join("\r\n")
  end

  def server_msg(code, *args)
    last = ":#{args.pop}"
    text = (args + [last]).join(' ')
    ":#{server_host} #{code} #{user_nick || '*'} #{text}"
  end

  # Representation of username@host (=email in our case) used with
  # some parts of the protocol.
  def email_split(email)
    email.split('@').join(' ')
  end
end
