class UserEditEvent < FlowdockEvent
  register_event "user-edit"

  def process
    # We get the event for each flow, but we should only send the nick change command once to the client
    new_nick = @message['content']['user']['nick']
    $logger.debug "Nick change: #{@user.nick} -> #{new_nick}"

    existing_user = @irc_connection.find_user_by_nick(new_nick)
    unless existing_user
      text = cmd.send(:render_nick, @user.irc_host, new_nick)
      @irc_connection.send_reply(text)

      @irc_connection.channels.values.each do |c|
        channel_user = c.find_user_by_id(@user.id)
        channel_user.nick = new_nick if channel_user
      end

      @irc_connection.nick = new_nick if @user_id == @user.id
    end
  end
end
