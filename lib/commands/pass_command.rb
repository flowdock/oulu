class PassCommand < Command
  register_command :PASS

  def set_data(args)
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
