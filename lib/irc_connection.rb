class IrcConnection < EventMachine::Connection
  attr_accessor :nick, :email, :password, :real_name, :channels, :last_ping_sent

  def initialize(*args)
    super

    @nick = nil
    @email = nil
    @password = nil
    @real_name = nil
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
    data.split("\r\n").select { |line| line != "\r\n" }.compact.each do |line|
      puts "Parsing #{line}"
      begin
        parse_line(line)
      rescue => ex
        puts "Error parsing line:"
        puts ex.to_s
        puts ex.backtrace.join("\n")
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
      puts "Error setting args #{args.inspect} for #{command.inspect}"
    end

    return nil unless command.valid?

    begin
      command.execute!
    rescue => ex
      puts "Error executing command #{command.inspect}"
      puts ex.to_s
      puts ex.backtrace.join("\n")
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
    http = EventMachine::HttpRequest.new('https://api.flowdock.com/v1/flows?users=1').
      get(:head => { 'authorization' => [email, password] })

    http.errback do
      puts "Error getting flows JSON"

      yield if block_given?
    end

    http.callback do
      @password = password
      process_flows_json(http.response)
      process_current_user(http.response_header["FLOWDOCK_USER"].to_i)
      @authenticated = true
      @flowdock_connection.start!

      # Only yield when this object is newly configured with proper data.
      yield if block_given?
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

    http = EventMachine::HttpRequest.new("https://api.flowdock.com/v1/flows/#{channel_flowdock_id}/messages").
      post(:head => { 'authorization' => [@email, @password], 'Content-Type' => 'application/json' },
           :body => msg_json)

    http.errback do
      puts "Error posting message to Flowdock"
    end

    http.callback do
      puts "Message posted"
    end
  end

  def send_reply(text)
    send_data(text + "\r\n")
  end

  # EventMachine's callback
  def unbind
    @flowdock_connection.close!
    puts "Connection closed"
  end

  protected

  def process_current_user(user_id)
    user = @channels.values.first.users.detect do |u|
      u.id == user_id
    end

    puts "Current user: #{user.inspect}"
    @email = user.email
    @real_name = user.name
    @nick = user.nick
  end

  # Initialize @channels
  def process_flows_json(json)
    puts "Processing flows JSON"

    data = MultiJson.decode(json)
    data.each do |flow_data|
      channel = IrcChannel.new(self, flow_data)
      @channels[channel.flowdock_id] = channel
    end
  end

  def receive_flowdock_event(json)
    message = MultiJson.decode(json)
    puts "Received message for #{@email}"

    channel = find_channel(message['flow'])
    return unless channel

    user = channel.find_user_by_id(message['user'])
    return unless user

    if message['event'] == 'message' && message['content'].is_a?(String)
      if i = outgoing_index(message)
        @outgoing_messages.delete_at(i)
        puts "Ignoring sent chat message"
      else
        puts "Chat message to #{channel.flowdock_id}"

        # TODO: refactor me: Flowdock Events should be similar to Commands,
        # with access to CommandViews
        cmd = Command.new(self)
        text = cmd.send(:render_privmsg, user.irc_host, channel.irc_id, message['content'])
        send_reply(text)
      end
    end
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
