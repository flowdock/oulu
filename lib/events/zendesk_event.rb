class ZendeskEvent < FlowdockEvent
  register_event "zendesk"

  def render
    @content = @message['content']

    zendesk_message = [@content['message'].split(/\n/).first]

    @content['latest_comment'].split(/\n/).each {|m|
      next if m.match(/\S/).nil? || m.match(/[^-]/).nil? # filter out lines containing only whitespace or dashes
      zendesk_message << m
    }

    ticket_text = team_inbox_event(
                  "Zendesk",
                  *zendesk_message
                )

    render_notice(IrcServer::FLOWDOCK_USER, @channel.irc_id, ticket_text)
  end
end
