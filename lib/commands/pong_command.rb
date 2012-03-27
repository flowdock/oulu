# TODO: request authentication separately from the PONG command.
class PongCommand < Command
  register_command :PONG

  def set_data(args)
    @value = args.first
  end

  def valid?
    !!@value && @value == irc_connection.last_ping_sent
  end

  # Normally no need to do anything, but during the authentication
  # handshake we PING user.
  def execute!
    unless authenticated?
      replies = motd_lines
      replies << nickserv_auth_notice
      send_replies replies
    end
  end

  protected

  def motd_lines
    [render_welcome, render_yourhost, render_created, render_motd_start,
      render_motd_line("For instructions, check out https://www.flowdock.com/help"),
      render_motd_end]
  end

  def nickserv_auth_notice
    render_notice(IrcServer::NICKSERV_HOST, user_nick, "Please identify via /msg NickServ identify <email> <password>")
  end
end
