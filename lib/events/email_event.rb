class EmailEvent < FlowdockEvent
  register_event "mail"

  def render
    email_text = team_inbox_event("Email", "#{@message['content']['from'][0]['address']}: #{@message['content']['subject']}")
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, email_text)
  end

  def valid?
    channel?
  end
end
