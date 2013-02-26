class PartEvent < FlowdockEvent

  register_event "backend.user.block"

  def process
    text = self.render
    @irc_connection.update_channel(@target) do
      @irc_connection.send_reply(text) if text
    end
  end

  def render
    parted_user = @target.find_user_by_id(@message['content'])
    if user
      render_user_part(parted_user.irc_host, @target.irc_id)
    end
  end

  def valid?
    channel?
  end

end
