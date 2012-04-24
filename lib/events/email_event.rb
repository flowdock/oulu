class EmailEvent < FlowdockEvent
  register_event "mail"

  def render
    email_text = team_inbox_event("Email", "#{@message['content']['subject']} <#{@message['content']['from'][0]['address']}>")
    render_notice(IrcServer::FLOWDOCK_USER, @channel.irc_id, email_text)
  end
end
