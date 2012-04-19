class EmailEvent < FlowdockEvent
  register_event "mail"

  def process
    email_text = team_inbox_event("Email", "#{@message['content']['subject']} <#{@message['content']['from'][0]['address']}>")
    text = cmd.send(:render_notice, IrcServer::FLOWDOCK_USER, @channel.irc_id, email_text)
    @irc_connection.send_reply(text)
  end
end
