class PresenceEvent < FlowdockEvent
  register_event "presence"

  STATES = {
      0 => :offline,
      1000000 => :idle,
      2000000 => :active
  }

  def process
    content = @message['content']
    irc_connection.channels.values.each do |channel|
      channel_user = channel.find_user_by_id(content['user_id'])
      if channel_user
        channel_user.presence = STATES[content['state']]
        channel_user.last_presence_update = Time.parse(content['updated_at'])
      end
    end
  end

  def valid?
    !!@message['content']
  end
end
