class PassCommand < Command
  register_command :PASS

  def set_data(args)
    # Some IRC clients send multi-word passwords as one argument, some forget
    # the colon and send it as multiple arguments.
    @email, @password = args.join(' ').split(' ', 2)
  end

  def valid?
    (!registered? && !@password.nil? && !@email.nil?)
  end

  def execute!
    irc_connection.password = @password
    irc_connection.email = @email
  end

end
