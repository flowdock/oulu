class ListCommand < Command
  register_command :LIST

  def set_data(args)
    @channels = (args.first || "").split(',')
  end

  def valid?
    registered?
  end

  def execute!
    replies = [] 
    if authenticated? && @channels.size == 0
      irc_connection.channels.values.each do |channel|
        replies << render_list_item(channel.irc_id, channel.users.count, channel.topic)
      end
    elsif authenticated?
      @channels.each do |channel|
        if channel = find_channel(channel)
          replies << render_list_item(channel.irc_id, channel.user.count, channel.topic)
        end
      end
    end
    replies << render_list_end
    send_replies(replies)
  end
end
