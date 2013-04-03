class PongCommand < Command
  include AuthenticationHelper
  register_command :PONG

  def set_data(args)
    @value = args.first
  end

  def valid?
    !!@value && @value == irc_connection.last_ping_sent
  end

  def execute!
    irc_connection.last_pong_received_at = Time.now
  end
end
