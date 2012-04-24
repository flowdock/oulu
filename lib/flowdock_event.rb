class FlowdockEvent
  class UnsupportedMessageError < StandardError; end
  class InvalidMessageError < StandardError; end

  include CommandViews

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

  def process
    text = self.render
    @irc_connection.send_reply(text)
  end

  protected

  def team_inbox_event(integration, *description)
    description.collect do |str|
      "[#{integration}] #{str}"
    end.push(team_inbox_link(integration)).join("\n")
  end

  def team_inbox_link(integration)
    "[#{integration}] Show in Flowdock: #{team_inbox_url(@message['id'])}"
  end

  def team_inbox_url(item_id)
    subdomain, flow = @channel.flowdock_id.split('/')
    "https://#{subdomain}.#{IrcServer::FLOWDOCK_DOMAIN}/flows/#{flow}#/influx/show/#{item_id}"
  end
end

# Load all events automatically
Dir[File.join(File.dirname(__FILE__), 'events', '*_event.rb')].each do |file|
  require file
end