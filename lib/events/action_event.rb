class ActionEvent < FlowdockEvent
  register_event "action"
  VALID_TYPES = %w(join block add_people)

  def process
    type = @message['content']['type']
    self.send(type) if VALID_TYPES.include?(type)
  end

  private

  def join
    @irc_connection.update_channel(channel) do
      joined_user = @channel.find_user_by_id(@message['user'])
      text = cmd.send(:render_user_join, joined_user.irc_host, @channel.irc_id)
      @irc_connection.send_reply(text)
    end
  end

  def block
    blocked_user = @channel.find_user_by_id(@message['content']['user'])
    text = cmd.send(:render_kick, @user.irc_host, blocked_user.nick, @channel.irc_id)
    @irc_connection.send_reply(text)
  end

  def add_people
    @irc_connection.update_channel(@channel) do
      @message['content']['message'].each do |joined_nick|
        joined_user = @channel.find_user_by_nick(joined_nick)
        text = cmd.send(:render_user_join, joined_user.irc_host, @channel.irc_id)
        @irc_connection.send_reply(text)
      end
    end
  end
end