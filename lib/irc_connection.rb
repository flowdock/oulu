class IrcConnection < EventMachine::Connection
  attr_accessor :nick, :email, :password, :real_name, :user_id, :channels, :last_ping_sent, :last_pong_received_at, :away_message, :client_ip, :client_port

  include EM::Protocols::LineText2
  include CommandViews

  def initialize(*args)
    super

    @nick = nil
    @email = nil
    @password = nil
    @real_name = nil
    @user_id = nil
    @client_ip = nil
    @client_port = nil
    @init_token = nil
    @authenticated = false
    @last_ping_sent = nil
    @last_pong_received_at = nil
    @away_message = nil
    @channels = {}
    @outgoing_messages = []

    # Initialize, but don't start.
    @flowdock_connection = FlowdockConnection.new(self)
    @flowdock_connection.message do |message|
      receive_flowdock_event(message)
    end
    @flowdock_connection.error do |error|
      $logger.info "Fatal connection error for #{email}, disconnecting"
      cmd = Command.new(self)
      send_reply(cmd.send(:render_quit, "Fatal connection error", false))
      quit!
    end
  end

  # In addition to connecting and registering, has the user successfully
  # authenticated with NickServ?
  def authenticated?
    @authenticated
  end

  # After connecting, has the user successfully issued NICK and USER?
  # User might or might not be authenticated.
  def registered?
    !!@nick && !!@email && !!@real_name
  end

  def receive_line(data)
    begin
      data.chomp!
      parse_line(data)
    rescue => ex
      $logger.error "Error parsing line:"
      $logger.error ex.to_s
      $logger.error ex.backtrace.join("\n")
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
      $logger.error ex.to_s
      $logger.error ex.backtrace.join("\n")
    end
  end

  def ping!
    ping = "FLOWDOCK-#{rand(1000000)}"
    self.last_ping_sent = ping
    cmd = Command.new(self)
    send_reply(cmd.send(:render_ping, ping))
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

  def find_channel_by_name(name)
    @channels.values.find do |channel|
      channel.irc_id == name
    end
  end

  def find_channel_by_id(id)
    @channels.values.find do |channel|
      channel.id == id
    end
  end

  def remove_channel(channel)
    @channels.delete(channel.flowdock_id)
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
    unknown_error_message = "An error occurred during authentication, please try again.\nIf the problem persists, contact us: support@flowdock.com."
    auth_error_message = "Authentication failed. Check username and password and try again."

    http = ApiHelper.new(email, password).get(ApiHelper.api_url("user"))
    http.errback do
      $logger.error "Error getting flows JSON for #{email}: Connection failed."
      yield(true, unknown_error_message) if block_given?
    end

    http.callback do
      begin
        if http.response_header.status == 200
          @password = password
          process_current_user(http.response)
          $logger.info("Authentication successfull for #{@user_id} (#{@email})")

          process_flows do |error|
            if error
              yield true, unknown_error_message
            elsif @channels.size > 0
              resolve_nick_conflicts!
              @authenticated = true
              @flowdock_connection.start!

              # Authentication successful
              yield false, ''
            else
              error_message = [
                "Seems that you don't have access to any flows.",
                "Log in and check your current subscription status: https://www.flowdock.com/",
              ].join("\n")
              yield true, error_message
            end
          end
        elsif http.response_header.status == 401
          yield true, auth_error_message
        else
          $logger.error "Authentication request failed for #{email} with status #{http.response_header.status} and message '#{http.response}'."
          yield true, unknown_error_message
        end
      rescue => ex
        $logger.error "Exception in authentication: #{ex.class}: #{ex.message}\n#{ex.backtrace.join("\n")}"
        yield true, unknown_error_message
      end
    end
  end

  def process_flows(&block)
    http = ApiHelper.new(@email, @password).get(ApiHelper.api_url("flows/all?users=1"))
    http.errback do
      $logger.error "Error getting flows JSON for #{@email}: Connection failed."
      yield true
    end

    http.callback do
      if http.response_header.status == 200
        begin
          process_flows_json(http.response)
          yield false
        rescue => ex
          $logger.error "Exception in processing flows for #{@email}: #{ex.to_s}"
          $logger.error ex.backtrace.join("\n")
          yield true
        end
      else
        $logger.error "Authentication request failed for #{@email} with status #{http.response_header.status} and message '#{http.response}'."
        yield true
      end
    end
  end

  def add_channel(flow_data)
    channel = IrcChannel.new(self, flow_data.merge('open' => false))
    update_channel(channel)
  end

  def update_channel(channel)
    $logger.info("Updating channel #{channel.id} for #{@email}")

    resource = "flows/find?id=#{channel.id}&users=1"
    http = ApiHelper.new(@email, @password).get(ApiHelper.api_url(resource))

    http.errback do
      $logger.error "Error getting flow JSON"
    end

    http.callback do
      if http.response_header.status == 200
        begin
          process_flow_json(channel, http.response)
          yield if block_given?
        rescue => ex
          $logger.error "Update channel exception: #{ex.to_s}"
          $logger.error ex.backtrace.join("\n")
        end
      else
        $logger.error "Failed to update channel #{channel.id} for #{@email}: Code #{http.response_header.status}: #{http.response}"
      end
    end
  end

  def update_flow(channel, message)
    http = ApiHelper.new(@email, @password).put(channel.url, { 'Content-Type' => 'application/json' }, MultiJson.dump(message))

    http.errback do
      $logger.error "Error updating Flow (#{@email}, #{channel.visible_name})"
      yield if block_given?
    end

    http.callback do
      if http.response_header.status == 200
        $logger.info "Flow update successful (#{@email}, #{channel.visible_name})"
      else
        $logger.info "Error updating Flow (#{@email}, #{channel.visible_name}). Api responded #{http.response_header.status}, #{http.response}"
      end
      yield if block_given?
    end
  end

  def restart_flowdock_connection!
    @flowdock_connection.restart!
  end

  def post_status_message(target, status_text)
    message = {
      :event => 'status',
      :app => 'chat',
      :content => encode(status_text)
    }
    post_message(target, message)
  end

  def post_chat_message(target, message_text)
    message = {
      :event => 'message',
      :app => 'chat',
      :content => encode(message_text)
    }
    if /^<([0-9]*)>/.match(message[:content])
        matches = /^<([0-9]*)>(.*)/.match(message[:content])
        parent= matches[1].to_i
        message[:content] = matches[2]
    end
    if parent
      msg_http = ApiHelper.new(@email, @password).get(target.url + "/messages/" + parent.to_s)
      msg_http.errback do
       $logger.error "Error getting thread info"
      end
      msg_http.callback do
       parent_info = MultiJson.load(msg_http.response)
       if parent_info["thread"]
         message[:thread_id] = parent_info["thread"]["id"]
       end
       post_message(target, message)
      end
    else
       post_message(target, message)
    end
  end

  # Async message posting
  def post_message(target, message)
    @outgoing_messages << target.build_message(message)
    resource = target.url + "/messages"

    msg_json = MultiJson.dump(message)
    http = ApiHelper.new(@email, @password).post(resource, { 'Content-Type' => 'application/json' }, msg_json)

    http.errback do
      $logger.error "Error posting message to Flowdock"
    end

    http.callback do
      if http.response_header.status == 201
        $logger.debug "Message posted"
        unless message[:thread_id]
          # Give the user the thread ID to use if it's a new thread
          response_data = MultiJson.load(http.response)
          send_reply(render_notice(IrcServer::FLOWDOCK_USER, @nick, "<#{response_data["id"]}> #{message[:content]}"))
        end
      else
        $logger.error "Error posting #{@email}'s message to Flowdock, api responded #{http.response_header.status}, #{http.response}"
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

  # FlowdockConnection needs to be restarted, since away status controls
  # the activity parameter of the stream.
  def set_away(text)
    old_away_message = @away_message
    @away_message = text

    # Only need to restart connection when changing from nil status to non-nil
    # or vice versa.
    if !!old_away_message ^ !!text && authenticated?
      @flowdock_connection.restart!
    end
  end

  # EventMachine's callback
  def unbind
    @flowdock_connection.close!
    $logger.debug "Connection closed (#{@client_ip}:#{@client_port})"
  end

  # EventMachine's callback, called immediately after connection is established
  def post_init
    client_port, client_ip = Socket.unpack_sockaddr_in(get_peername)
    unless IrcServer::EXPECT_PROXY_PROTOCOL
      @client_port = client_port
      @client_ip = client_ip
    end
    $logger.debug "Received connection (#{client_ip}:#{client_port})"
    cmd = Command.new(self)
    send_reply(cmd.send(:render_connected))
  rescue
    $logger.info "Received connection (unknown)"
  end

  # All users I see in deterministic order
  def all_users
    @channels.values.map(&:users).flatten.sort_by(&:id)
  end

  def unique_users
    all_users.uniq(&:id)
  end

  protected

  def process_current_user(json)
    user = MultiJson.load(json)
    @user_id = user["id"]
    @real_name = user["name"]
    @nick = user["nick"]
    @email = user["email"]
  rescue => ex
    $logger.error "Exception in processing curent user. #{ex.class}: #{ex.message}\n#{ex.backtrace.join("\n")}"
  end

  # Initialize @channels
  def process_flows_json(json)
    $logger.debug "Processing flows JSON"

    data = MultiJson.load(json)
    data.each do |flow_data|
      channel = IrcChannel.new(self, flow_data)
      @channels[channel.flowdock_id] = channel
      $logger.info "Processed channel: #{channel}"
    end
  end

  # Update channel
  def process_flow_json(channel, json)
    $logger.debug "Processing flow JSON"

    data = MultiJson.load(json)
    channel.update(data) do
      @channels[channel.flowdock_id] = channel if !@channels.has_key?(channel.flowdock_id)
      resolve_nick_conflicts!
    end
  end

  # When processing flow data, make sure that there are no users with different user IDs
  # and same nicks. Flowdock doesn't enforce unique nicks.
  def resolve_nick_conflicts!
    duplicates = duplicate_nick_users

    duplicates.dup.each do |user|
      new_nick = generate_unique_nick(user, duplicates)
      update_user_nick!(user, new_nick)
      duplicates << user # Consider newly generated nicks when checking further duplicates.
    end
  end

  # An array of individual channel users, who have colliding nicks with other users
  # in their visibility.
  def duplicate_nick_users
    seen_nicks = { @nick => find_user_by_id(@user_id) }        # Seen myself already

    all_users.each_with_object([]) do |user, result|           # Filling a result array
      seen = seen_nicks[user.nick.downcase]

      if seen && seen.id != user.id
        result << user
      else
        seen_nicks[user.nick.downcase] = user
      end
    end.uniq { |user| user.id }
  end

  def generate_unique_nick(user, duplicates)
    free_extension = (2..10).detect do |n|
      !duplicates.map { |u| u.nick.downcase }.include?((user.nick + n.to_s).downcase)
    end

    user.nick + free_extension.to_s
  end

  # We need to update all occurences of this user, because user belongs to
  # several channels.
  def update_user_nick!(user, nick)
    @channels.values.each do |channel|
      channel_user = channel.find_user_by_id(user.id)
      channel_user.nick = nick if channel_user
    end
  end

  # TODO: once some message types have been implemented, refactor this out from IrcConnection.
  def receive_flowdock_event(json)
    message = MultiJson.load(json)
    $logger.debug "Received message for #{@email}"

    event = FlowdockEvent.from_message(self, message)
    event.process if event && event.valid?
  rescue FlowdockEvent::UnsupportedMessageError => e
    $logger.debug "Unsupported Flowdock event: #{e.to_s}"
  rescue => e
    $logger.error "Error in processing Flowdock event: #{e.to_s}"
    $logger.error "Message: #{message.inspect}"
    $logger.error "Backtrace:"
    $logger.error e.backtrace.join("\n")
  end

  def outgoing_index msg
    @outgoing_messages.each_index do |i|
      o = @outgoing_messages[i]
      match = o.all? do |k, incoming|
        old = msg[k.to_s]
        # make sure that when comparing messages we normalize them
        # before that a message containing emoji string like :computer:
        # would be echoed again, this time with emoji character
        #
        # XXX there are some emoji codes which will be parsed in a weird way
        # for example sending :+1: will result in flowdock API sending back
        # :thumbsup: emoji... There are probably other "aliases" like that...
        EmojiCleaner.perform(old) == EmojiCleaner.perform(incoming)

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
