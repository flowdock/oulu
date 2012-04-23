class JiraEvent < FlowdockEvent
  register_event "jira"

  def process
    @content = @message['content']
    action = case @content['event_type']
      when 'create'
        'created'
      when 'close'
        'closed'
      when 'resolve'
        'resolved'
      when 'comment'
        'commented'
      when 'update'
        'updated'
      when 'start_work'
        'started working on'
    end
    description = ["#{@content['user_name']} #{action} issue: #{@message['content']['issue_summary']} #{@message['content']['issue_url']}"]
    description << "> #{first_line(@content['comment_body'])}" if @content['event_type'] == 'comment'

    jira_text = team_inbox_event("JIRA", *description)
    text = cmd.send(:render_notice, IrcServer::FLOWDOCK_USER, @channel.irc_id, jira_text)
    @irc_connection.send_reply(text)
  end
end
