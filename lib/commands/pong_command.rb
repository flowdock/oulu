# TODO: request authentication separately from the PONG command.
class PongCommand < Command
  include AuthenticationHelper
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
      if irc_connection.email && irc_connection.password
        authentication_send(irc_connection.email, irc_connection.password)
      else
        replies = motd_lines
        replies << nickserv_auth_notice
        send_replies replies
      end
    end


  end

  protected

  def motd_lines
    [render_welcome, render_yourhost, render_created, render_motd_start,
      render_motd_line("For instructions, check out https://www.flowdock.com/help/irc"),
      render_motd_line(""),
      render_motd_line("This server software is open source, and your contributions are"),
      render_motd_line("welcome. See https://github.com/flowdock/oulu"),
      render_motd_line(""),
      render_motd_line("Flowdock is in active development, and any feedback is appreciated."),
      render_motd_line("You email us at team@flowdock.com."),
      render_motd_end]
  end

  def nickserv_auth_notice
    render_notice(IrcServer::NICKSERV_HOST, user_nick, "Please identify via /msg NickServ identify <email> <password>")
  end
end
