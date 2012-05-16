class AwayCommand < Command
  register_command :AWAY

  def set_data(args)
    @message = args.first
  end

  def valid?
    true
  end

  def execute!
    irc_connection.set_away(@message)

    if @message
      send_reply(render_set_away)
    else
      send_reply(render_unset_away)
    end
  end
end
