class UserCommand < Command
  register_command :USER

  USERNAME_REGEX = /^[^\0\r\n @]+$/

  def set_data(args)
    if args.size == 4
      @user_name = args.first.sub(/@.*/, '')
      @real_name = args.last
    end
  end

  def valid?
    !!@user_name && !!@real_name && !registered?
  end

  def execute!
    if @user_name.match(USERNAME_REGEX)
      irc_connection.email = "#{@user_name}@unknown"
      irc_connection.real_name = @real_name

      if registered? and !irc_connection.last_ping_sent 
        ping = "FLOWDOCK-#{rand(1000000)}"
        irc_connection.last_ping_sent = ping
        send_reply(render_ping(ping))
      end
    else
      send_reply(render_quit("Invalid Username", false)) 
      irc_connection.quit!
    end
  end
end
