class ActionEvent < FlowdockEvent
  register_event "action"

  def valid?
    ["join", "block", "add_people"].include?(@message['content']['type'])
  end

  def process
    self.send(@message['content']['type'])
  end

  private

  def join
    @irc_connection.update_channel(channel) do
      joined_user = @channel.find_user_by_id(@message['user'])
      text = cmd.send(:render_user_join, joined_user.irc_host, @channel.irc_id)
      $logger.debug text
      @irc_connection.send_reply(text)
    end
  end

  def block
    blocked_user = @channel.find_user_by_id(@message['content']['user'])
    text = cmd.send(:render_kick, @user.irc_host, blocked_user.nick, @channel.irc_id)
    $logger.debug text
    @irc_connection.send_reply(text)
  end

  def add_people
    @irc_connection.update_channel(@channel) do
      @message['content']['message'].each do |joined_nick|
        joined_user = @channel.find_user_by_nick(joined_nick)
        text = cmd.send(:render_user_join, joined_user.irc_host, @channel.irc_id)
        $logger.debug text
        @irc_connection.send_reply(text)
      end
    end
  end
end