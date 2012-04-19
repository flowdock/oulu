class WhowasCommand < Command
  register_command :WHOWAS

  def set_data(args)
    @nick = args.first
    @nick.downcase! if @nick
  end

  def valid?
    !!@nick
  end

  def execute!
    reply = render_was_no_such_nick(@nick)
    send_reply(reply)
  end
end
