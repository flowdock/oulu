class NickCommand < Command
  register_command :NICK

  NICK_REGEX = /^[a-zA-Z0-9\[\]`_\-\^{\|}]+$/

  def set_data(args)
    @new_nick = args.first
  end

  def valid?
    !!@new_nick
  end

  def execute!
    if registered? or !@new_nick.match(NICK_REGEX)
      send_reply(render_nick_error(@new_nick))
    else
      irc_connection.nick = @new_nick
    end
  end
end
