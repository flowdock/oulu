class ModeCommand < Command
  register_command :MODE

  def set_data(args)
    @target = args.first

    if args.size == 2
      @params = args.last
    end
  end

  def valid?
    !!@target
  end

  def execute!
    # Retrieving my own mode
    if @target.downcase == user_nick.downcase
      send_reply(render_mode(server_host, user_nick, IrcServer::USER_DEFAULT_MODE))
    elsif channel = find_channel(@target)
      # Retrieving channel ban list
      if @params == '+b'
        send_reply(render_end_of_ban_list(channel.irc_id))
      # Retrieving channel mode
      else
        send_reply(render_channel_modes(channel.irc_id, IrcServer::CHANNEL_DEFAULT_MODE))
      end
    else
      # ignore
    end
  end
end
