class ActionEvent < FlowdockEvent
  register_event "action"
  VALID_TYPES = %w(join add_people)

  def process
    type = @message['content']['type']
    return unless VALID_TYPES.include?(type)
    if ['join', 'add_people'].include?(type)
      @irc_connection.update_channel(@target) do
        text = self.render
        @irc_connection.send_reply(text) if text
      end
    else
      text = self.render
      @irc_connection.send_reply(text) if text
    end
  end

  def render
    type = @message['content']['type']
    self.send(type)
  end

  def valid?
    channel?
  end

  private

  def join
    joined_user = @target.find_user_by_id(@message['user'])
    if joined_user
      render_user_join(joined_user.irc_host, @target.irc_id)
    end
  end

  def add_people
    @message['content']['message'].collect do |joined_nick|
      joined_user = @target.find_user_by_nick(joined_nick)
      if joined_user
        render_user_join(joined_user.irc_host, @target.irc_id)
      end
    end.compact.join("\r\n")
  end
end
