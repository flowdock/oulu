class PartCommand < Command
  register_command :PART

  def set_data(args)
    @channels = (args.first || "").split(',')
  end

  def valid?
    !!@channels && registered?
  end

  def execute!
    @channels.each do |c|
      if authenticated? && channel = find_channel(c)
        if channel.open?
          channel.part!
          send_reply(render_user_part(user_irc_host, channel.irc_id))
        else
          send_reply(render_not_on_channel(channel.irc_id))
        end
      else
        send_reply(render_no_such_channel(c))
      end
    end
  end

end
