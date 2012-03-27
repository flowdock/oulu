class PingCommand < Command
  register_command :PING

  def set_data(args)
    @value = args.first
  end

  def valid?
    !!@value
  end

  def execute!
    send_reply(render_pong(@value))
  end
end
