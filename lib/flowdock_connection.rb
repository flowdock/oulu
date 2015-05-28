class FlowdockConnection
  RESPONSE_STATUS_ERROR = /Unexpected response status (\d{3})/

  def initialize(irc_connection)
    @source = nil
    @on_message_block = nil
    @irc_connection = irc_connection
    @errors = []
    @restarts = 0
  end

  def message(&block)
    @on_message_block = block
  end

  def error(&block)
    @errors << block
  end

  def start!
    flows = @irc_connection.channels.values.select(&:open?).map(&:visible_name)
    username = @irc_connection.email
    password = @irc_connection.password

    # Control user's Flowdock activity based on the away message.
    active = if @irc_connection.away_message
      'idle'
    else
      'true'
    end

    @source = EventMachine::EventSource.new((ENV["FLOWDOCK_UNSECURE_HTTP"] ? "http" : "https") + "://stream.#{IrcServer::FLOWDOCK_DOMAIN}/flows",
      { 'filter' => flows.join(','), 'active' => active, 'user' => 1 },
      { 'Accept' => 'text/event-stream',
        'authorization' => [username, password] })

    @source.message(&@on_message_block)
    @source.inactivity_timeout = 90

    @source.open do
      @restarts = 0
    end

    @source.error do |error|
      $logger.error "Error reading EventSource for #{username}: #{error.inspect}"
      if @source.ready_state == EventMachine::EventSource::CLOSED
        if internal_server_error?(error) && @restarts < 3
          @restarts += 1
          EventMachine::Timer.new(3) do
            restart!
          end
        else
          @errors.each { |handler| handler.call error }
        end
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

  private

  def internal_server_error?(error)
    match = error.match RESPONSE_STATUS_ERROR
    match && (match[1].to_i == 409 || match[1].to_i >= 500)
  end
end
