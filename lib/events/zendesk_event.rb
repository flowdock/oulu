class ZendeskEvent < FlowdockEvent
  register_event "zendesk"

  def render
    content = @message['content']

    zendesk_message = [
      content['message'].split(/\n/).first,
      content['url']
    ]

    ticket_text = team_inbox_event(
                  "Zendesk",
                  *zendesk_message
                )

    render_notice(IrcServer::FLOWDOCK_USER, @channel.irc_id, ticket_text)
  end
end
