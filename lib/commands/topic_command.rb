class TopicCommand < Command
  register_command :TOPIC

  def set_data(args)
    @target = args.first
    @args = args
  end

  def valid?
    !!@target && registered? && authenticated?
  end

  def execute!
    channel = find_channel(@target)

    reply = if @args.size > 1
      # Tried to set a new topic
      render_nochanmodes(channel.irc_id)
    elsif channel
      render_topic(channel.irc_id, channel.topic)
    else
      render_no_such_channel(@target)
    end

    send_reply reply
  end
end
