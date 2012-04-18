class EmailEvent < FlowdockEvent
  register_event "mail"

  def process
    email_text = [
      "[Email] #{@message['content']['subject']} <#{@message['content']['from'][0]['address']}>",
    ].push(
        team_inbox_link("Email", @message['id'])
      ).join("\n")

    text = cmd.send(:render_notice, IrcServer::FLOWDOCK_USER, @channel.irc_id, email_text)
    @irc_connection.send_reply(text)
  end
end
