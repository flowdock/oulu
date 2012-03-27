class QuitCommand < Command
  register_command :QUIT

  def set_data(args)
    @message = args.first
  end

  def valid?
    true
  end

  def execute!
    send_reply(render_quit)

    irc_connection.quit!
  end
end
