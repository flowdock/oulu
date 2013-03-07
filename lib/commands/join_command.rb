class JoinCommand < Command
  register_command :JOIN

  def set_data(args)
    @target = args.first
  end

  def valid?
    !!@target and registered?
  end

  def execute!
    send_reply(render_no_such_channel(@target)) unless authenticated? && find_channel(@target)
  end
end
