class PassCommand < Command
  register_command :PASS

  def set_data(args)
    @password = args.first
  end

  def valid?
    (!registered? && !@password.nil?)
  end

  def execute!
    irc_connection.password = @password
    # just save the password, the PASS command is issued before USER/NICK,
    #   so we can't do anything yet.
  end

end
