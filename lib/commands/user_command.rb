class UserCommand < Command
  register_command :USER

  def set_data(args)
    if args.size == 4
      @user_name = args.first
      @real_name = args.last
    end
  end

  def valid?
    !!@user_name && !!@real_name && !authenticated?
  end

  def execute!
    irc_connection.email = "#{@user_name}@unknown"
    irc_connection.real_name = @real_name

    ping = "FLOWDOCK-#{rand(1000000)}"
    irc_connection.last_ping_sent = ping
    send_reply(render_ping(ping))
  end
end
