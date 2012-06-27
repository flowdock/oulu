class FlowdockConnection
  def initialize(irc_connection)
    @source = nil
    @on_message_block = nil
    @irc_connection = irc_connection
    @errors = []
  end

  def message(&block)
    @on_message_block = block
  end

  def error(&block)
    @errors << block
  end

  def start!
    flows = @irc_connection.channels.values.map(&:flowdock_id)
    username = @irc_connection.email
    password = @irc_connection.password

    # Control user's Flowdock activity based on the away message.
    active = if @irc_connection.away_message
      'idle'
    else
      'true'
    end

    @source = EventMachine::EventSource.new("https://stream.#{IrcServer::FLOWDOCK_DOMAIN}/flows",
      { 'filter' => flows.join(','), 'active' => active },
      { 'Accept' => 'text/event-stream',
        'authorization' => [username, password] })

    @source.message(&@on_message_block)
    @source.inactivity_timeout = 90

    @source.error do |error|
      $logger.error "Error reading EventSource for #{username}: #{error.inspect}"
      if @source.ready_state == EventMachine::EventSource::CLOSED
        @errors.each { |handler| handler.call error }
      end
    end

    $logger.info "Connecting #{username} to #{flows.size} flows, active: #{active}"

    @source.start
  end

  def close!
    $logger.debug "Closing EventSource"
    @source.close if @source
  end

  def restart!
    close!
    start!
  end
end
