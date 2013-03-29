class JoinCommand < Command
  register_command :JOIN

  def set_data(args)
    @channels = args.first.split(',')
  end

  def valid?
    !!@channels and registered?
  end

  def execute!
    @channels.each do |channel|
      send_reply(render_no_such_channel(channel)) unless authenticated? && find_channel(channel)
    end
  end
end
