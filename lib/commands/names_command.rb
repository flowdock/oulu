class NamesCommand < Command
  register_command :NAMES

  def set_data(args)
    @channel = args.first
  end

  def valid?
    !!@channel && registered?
  end

  def execute!
    channel = find_channel(@channel)

    if channel
      nicks = channel.users.map { |user| user.nick }

      send_replies([render_names_nicks(channel.irc_id, nicks),
                    render_names_end(channel.irc_id)])
    else
      send_reply(render_no_such_nick(channel))
    end
  end
end
