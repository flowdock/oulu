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
    if authenticated?
      find_channels.each do |channel|
        replies << render_list_item(channel.irc_id, channel.users.count, channel.topic)
      end
    end
    replies << render_list_end
    send_replies(replies)
  end

  def find_channels
    if @channels.size == 0
      irc_connection.channels.values
    else
      @channels.map{|channel| find_channel(channel)}.compact
    end
  end
end
