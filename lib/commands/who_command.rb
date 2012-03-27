class WhoCommand < Command
  register_command :WHO

  def set_data(args)
    @target = args.first
  end

  def valid?
    !!@target
  end

  def execute!
    channel = find_channel(@target)
    
    replies = if channel
      channel.users.map do |user|
        render_who(channel.irc_id, user.nick, user.email, user.name)
      end + [render_who_end(channel.irc_id)]
    else
      [render_who_end(@target)]
    end

    send_replies replies
  end
end
