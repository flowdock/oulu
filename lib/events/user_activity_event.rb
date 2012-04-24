class UserActivityEvent < FlowdockEvent
  register_event "activity.user"

  # We get the activity for each flow separately, but in irc it's global
  def process
    return unless @message['sent']

    irc_connection.channels.values.each do |channel|
      channel_user = channel.find_user_by_id(@user.id)
      channel_user.update_last_activity(@message['sent']) if channel_user
    end
  end
end
