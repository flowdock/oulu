class FlowdockEvent

  EVENTS = %w(message comment file action user-edit)

  def initialize(irc_connection, message)
    @irc_connection = irc_connection
    @message = message
    @channel = @irc_connection.find_channel(@message['flow'])
    return unless @channel

    @user = @channel.find_user_by_id(@message['user'])
    return unless @user

    @event = @message['event']
    if EVENTS.include?(@event)
      self.send(@event.gsub(/-/, '_'))
    else
      $logger.debug "Ignored event '#{@event}'"
    end
  end

  private

  def message
    return unless @message['content'].is_a?(String)

    if !@irc_connection.remove_outgoing_message(@message)
      $logger.debug "Chat message to #{@channel.flowdock_id}"

      # TODO: refactor me: Flowdock Events should be similar to Commands,
      # with access to CommandViews
      cmd = Command.new(@irc_connection)
      text = cmd.send(:render_privmsg, @user.irc_host, @channel.irc_id, @message['content'])
      @irc_connection.send_reply(text)
    end
  end

  def comment
    return unless @message['content'] && @message['content']['text']

    cmd = Command.new(self)
    text = cmd.send(:render_privmsg, @user.irc_host, @channel.irc_id, "[#{@message['content']['title']}] << #{@message['content']['text']}")
    @irc_connection.send_reply(text)
  end

  def file
    return unless @message['content']

    (organization, flow) = @channel.flowdock_id.split('/')
    url = "https://#{organization}.#{IrcServer::FLOWDOCK_DOMAIN}#{@message['content']['path']}"
    cmd = Command.new(@irc_connection)
    text = cmd.send(:render_privmsg, @user.irc_host, @channel.irc_id, url)
    @irc_connection.send_reply(text)
  end

  def user_edit
    return unless @message['content'] && @message['content']['user']

    # We get the event for each flow, but we should only send the nick change command once to the client
    new_nick = @message['content']['user']['nick']
    $logger.debug "Nick change: #{@user.nick} -> #{new_nick}"

    existing_user = @irc_connection.find_user_by_nick(new_nick)
    unless existing_user
      cmd = Command.new(@irc_connection)
      text = cmd.send(:render_nick, @user.irc_host, new_nick)
      @irc_connection.send_reply(text)

      @irc_connection.channels.values.each do |c|
         channel_user = c.find_user_by_id(@user.id)
         channel_user.nick = new_nick if channel_user
      end

      @irc_connection.nick = new_nick if @user_id == @user.id
    end
  end

  def action
    type = @message['content']['type']
    self.send(type) if ["join", "block", "add_people"].include?(type)
  end

  def join
    @irc_connection.update_names(channel) do
      cmd = Command.new(@irc_connection)
      text = cmd.send(:render_user_join, @user.irc_host, @channel.irc_id)
      @logger.debug text
      @irc_connection.send_reply(text)
    end
  end

  def block
    blocked_user = @channel.find_user_by_id(@message['content']['user'])
    cmd = Command.new(@irc_connection)
    text = cmd.send(:render_kick, @user.irc_host, blocked_user.nick, @channel.irc_id)
    @logger.debug text
    @irc_connection.send_reply(text)
  end

  def add_people
    @irc_connection.update_names(@channel) do
      @message['content']['message'].each do |joined_nick|
        joined_user = @channel.find_user_by_nick(joined_nick)
        cmd = Command.new(@irc_connection)
        text = cmd.send(:render_user_join, joined_user.irc_host, @channel.irc_id)
        @logger.debug text
        @irc_connection.send_reply(text)
      end
    end
  end

end