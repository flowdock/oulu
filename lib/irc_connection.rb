class IrcConnection < EventMachine::Connection
  attr_accessor :nick, :email, :password, :real_name, :user_id, :channels, :last_ping_sent

  def initialize(*args)
    super

    @nick = nil
    @email = nil
    @password = nil
    @real_name = nil
    @user_id = nil
    @init_token = nil
    @authenticated = false
    @last_ping_sent = nil
    @channels = {}
    @outgoing_messages = []

    # Initialize, but don't start.
    @flowdock_connection = FlowdockConnection.new(self)
    @flowdock_connection.message do |message|
      receive_flowdock_event(message)
    end
  end

  def authenticated?
    @authenticated
  end

  def receive_data(data)
    data.split(/\r?\n/).select { |line| line != "\r\n" && line != "\n" }.compact.each do |line|
      $logger.debug "Parsing #{line}"
      begin
        parse_line(line)
      rescue => ex
        $logger.error "Error parsing line:"
        $logger.debug ex.to_s
        $logger.debug ex.backtrace.join("\n")
      end
    end
  end

  def parse_line(data)
    klass, args = IrcParser.parse(data)
    return nil if klass.nil?
    command = klass.new(self)

    begin
      command.set_data(args)
    rescue => ex
      $logger.error "Error setting arguments for #{command.class.to_s}"
      $logger.debug "#{args.inspect} for #{command.inspect}"
    end

    return nil unless command.valid?

    begin
      command.execute!
    rescue => ex
      $logger.error "Error executing command #{command.class.to_s}"
      $logger.debug ex.to_s
      $logger.debug ex.backtrace.join("\n")
    end
  end

  def quit!
    EventMachine.next_tick do
      close_connection
    end
  end

  def find_channel(orig_id)
    return nil unless orig_id

    flowdock_id = orig_id.sub(':', '/').sub('#', '')
    @channels[flowdock_id]
  end

  def find_user_by_id(id)
    @channels.values.each do |channel|
      user = channel.find_user_by_id(id)
      return user if user
    end

    nil
  end

  def find_user_by_nick(nick)
    @channels.values.each do |channel|
      user = channel.find_user_by_nick(nick)
      return user if user
    end

    nil
  end

  # Async authentication: sends channel joins when ready.
  # Call authenticated? in the yield block to make sure it succeeded.
  def authenticate(email, password, &block)
    http = EventMachine::HttpRequest.new("https://api.#{IrcServer::FLOWDOCK_DOMAIN}/v1/flows?users=1").
      get(:head => { 'authorization' => [email, password] })

    http.errback do
      $logger.error "Error getting flows JSON"

      yield(true, "Authentication failed. Check username and password and try again.") if block_given?
    end

    http.callback do
      error, error_message = nil, ''
      if http.response_header.status == 200
        begin
          @password = password
          process_flows_json(http.response)
          if @channels.size > 0
            process_current_user(http.response_header["FLOWDOCK_USER"].to_i)
            @authenticated = true
            @flowdock_connection.start!
          else
            error = true
            error_message = [
                "Seems that you don't have access to any flows.",
                "Log in and check your current subscription status: https://www.flowdock.com/",
              ].join("\n")
          end
        rescue => ex
          error = true
          error_message = "An error occurred, please try again.\nIf the problem persists, contact us: team@flowdock.com."
          $logger.error "Authentication exception: #{ex.to_s}"
          $logger.debug ex.backtrace.join("\n")
        end
      elsif http.response_header.status == 401
        error = true
        error_message = "Authentication failed. Check username and password and try again."
      end

      # Only yield when this object is newly configured with proper data.
      yield(error, error_message) if block_given?
    end
  end

  def update_channel(channel)
    http = EventMachine::HttpRequest.new("https://api.#{IrcServer::FLOWDOCK_DOMAIN}/v1/flows/#{channel.flowdock_id}").
      get(:head => { 'authorization' => [@email, @password] })

    http.errback do
      $logger.error "Error getting flow JSON"
    end

    http.callback do
      if http.response_header.status == 200
        process_flow_json(http.response)
        yield if block_given?
      end
    end
  end

  # Async message posting
  def post_message(channel_flowdock_id, message_text)
    message = {
      :event => 'message',
      :app => 'chat',
      :content => encode(message_text)
    }

    @outgoing_messages << message.merge(:flow => channel_flowdock_id.sub('/', ':'))

    msg_json = MultiJson.encode(message)

    http = EventMachine::HttpRequest.new("https://api.#{IrcServer::FLOWDOCK_DOMAIN}/v1/flows/#{channel_flowdock_id}/messages").
      post(:head => { 'authorization' => [@email, @password], 'Content-Type' => 'application/json' },
           :body => msg_json)

    http.errback do
      $logger.error "Error posting message to Flowdock"
    end

    http.callback do
      if http.response_header.status == 200
        $logger.debug "Message posted"
      else
        $logger.error "Error posting message to Flowdock, api responded #{http.response_header.status}"
      end
    end
  end

  def send_reply(text)
    send_data(text + "\r\n")
  end

  def remove_outgoing_message(message)
    if i = outgoing_index(message)
      @outgoing_messages.delete_at(i)
      return true
    end
    false
  end

  # EventMachine's callback
  def unbind
    @flowdock_connection.close!
    $logger.info "Connection closed"
  end

  protected

  def process_current_user(user_id)
    user = @channels.values.first.users.detect do |u|
      u.id == user_id
    end

    $logger.debug "Current user: #{user.inspect}"
    @user_id = user.id
    @email = user.email
    @real_name = user.name
    @nick = user.nick
  end

  # Initialize @channels
  def process_flows_json(json)
    $logger.debug "Processing flows JSON"

    data = MultiJson.decode(json)
    data.each do |flow_data|
      channel = IrcChannel.new(self, flow_data)
      @channels[channel.flowdock_id] = channel
    end
  end

  # Update channel
  def process_flow_json(json)
    $logger.debug "Processing flow JSON"

    data = MultiJson.decode(json)
    @channels[data["id"]].update(data)
  end

  # TODO: once some message types have been implemented, refactor this out from IrcConnection.
  def receive_flowdock_event(json)
    message = MultiJson.decode(json)
    $logger.debug "Received message for #{@email}"

    event = FlowdockEvent.from_message(self, message)
    event.process
  rescue FlowdockEvent::UnsupportedMessageError => e
    $logger.debug "Unsupported Flowdock event: #{e.to_s}"
  rescue => e
    $logger.error "Error in processing Flowdock event: #{e.to_s}"
    $logger.debug "Backtrace:"
    $logger.debug e.backtrace.join("\n")
  end

  def outgoing_index msg
    @outgoing_messages.each_index do |i|
      o = @outgoing_messages[i]
      match = o.all? do |k, v|
        msg[k.to_s] == v
      end
      return i if match
    end
    return false
  end

  def encode string
    if string.force_encoding(Encoding::UTF_8).valid_encoding?
      string
    else
      string.force_encoding(Encoding::WINDOWS_1252).encode(Encoding::UTF_8, :invalid => :replace, :undef => :replace)
    end
  end
end
