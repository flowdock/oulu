class Command
  include CommandViews

  def initialize(irc_connection)
    @irc_connection = irc_connection
  end

  def set_data(args)
    raise NotImplementedError.new("You need to override set_data")
  end

  def execute!
    raise NotImplementedError.new("You need to override execute!")
  end

  def valid?
    raise NotImplementedError.new("You need to override valid?")
  end

  protected

  def self.register_command(cmd)
    IrcParser.register_command(cmd, self)
  end

  def irc_connection
    @irc_connection
  end

  def user_nick
    irc_connection.nick
  end

  def user_email
    irc_connection.email
  end

  def user_real_name
    irc_connection.real_name
  end

  def user_irc_host
    "#{user_nick}!#{user_email}"
  end

  def server_host
    IrcServer::HOST
  end

  def authenticated?
    irc_connection.authenticated?
  end

  def registered?
    irc_connection.registered?
  end

  def find_channel(name)
    irc_connection.find_channel(name)
  end

  def send_reply(text)
    irc_connection.send_reply(text)
  end

  def send_replies(lines)
    text = lines.join("\r\n")
    irc_connection.send_reply(text)
  end
end

# Load all commands automatically
Dir[File.join(File.dirname(__FILE__), 'commands', '*_command.rb')].each do |file|
  require file
end
