class NickCommand < Command
  register_command :NICK

  def set_data(args)
    @new_nick = args.first
  end

  def valid?
    !!@new_nick
  end

  def execute!
    if authenticated?
      send_reply(render_nick_error(@new_nick))
    else
      reply = render_nick(user_irc_host, @new_nick)
      irc_connection.nick = @new_nick
      send_reply(reply)
    end
  end
end
