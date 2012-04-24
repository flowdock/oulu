class ActionEvent < FlowdockEvent
  register_event "action"
  VALID_TYPES = %w(join block add_people)

  def process
    type = @message['content']['type']
    return unless VALID_TYPES.include?(type)
    if ['join', 'add_people'].include?(type)
      @irc_connection.update_channel(@channel) do
        self.render
      end
    else
      self.render
    end
  end

  def render
    type = @message['content']['type']
    self.send(type)
  end

  private

  def join
    joined_user = @channel.find_user_by_id(@message['user'])
    render_user_join(joined_user.irc_host, @channel.irc_id)
  end

  def block
    blocked_user = @channel.find_user_by_id(@message['content']['user'])
    render_kick(@user.irc_host, blocked_user.nick, @channel.irc_id)
  end

  def add_people
    @message['content']['message'].collect do |joined_nick|
      joined_user = @channel.find_user_by_nick(joined_nick)
      render_user_join(joined_user.irc_host, @channel.irc_id)
    end.join("\r\n")
  end
end
