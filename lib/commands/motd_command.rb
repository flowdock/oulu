class MotdCommand < Command
  include AuthenticationHelper
  register_command :MOTD

  def set_data(args)
  end

  def valid?
    registered?
  end

  def execute!
    motd_send 
  end
end
