class PassCommand < Command
  register_command :PASS

  def set_data(args)
    @email = args.first
    @password = args[1]
  end

  def valid?
    (registered? == false && !@password.nil? && !@email.nil?)
  end

  def execute!
    irc_connection.password = @password
    irc_connection.email = @email
  end

end