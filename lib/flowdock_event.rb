class FlowdockEvent
  class UnsupportedMessageError < StandardError; end
  class InvalidMessageError < StandardError; end

  attr_accessor :irc_connection, :channel, :user, :message
  @@registered_events = {}

  def initialize(irc_connection, channel, user, message)
    @irc_connection = irc_connection
    @channel = channel
    @user = user
    @message = message
  end

  def self.register_event(command)
    @@registered_events[command.to_s] = self
  end

  def self.from_message(irc_connection, message)
    event_type = @@registered_events[message['event']]
    raise UnsupportedMessageError, "Event '#{message['event']}' is not supported" if event_type.nil?

    channel = irc_connection.find_channel(message['flow'])
    raise InvalidMessageError, "Event must have a channel" unless channel

    user = channel.find_user_by_id(message['user'])

    event_type.new(irc_connection, channel, user, message)
  end

  def valid?
    raise NotImplementedError.new("You need to override valid?")
  end

  def process
    raise NotImplementedError.new("You need to override process")
  end

  protected

  def cmd
    Command.new(@irc_connection)
  end
end

# Load all events automatically
Dir[File.join(File.dirname(__FILE__), 'events', '*_event.rb')].each do |file|
  require file
end