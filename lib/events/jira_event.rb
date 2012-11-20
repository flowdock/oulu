class JiraEvent < FlowdockEvent
  register_event "jira"
  EVENT_TYPES = {"create" => "created", "close" => "closed", "resolve" => "resolved",
    "comment" => "commented", "update" => "updated", "start_work" => "started working on"}

  def render
    @content = @message['content']
    action = EVENT_TYPES[@content['event_type']]
    return if action.nil?

    description = ["#{@content['user_name']} #{action} issue: #{@message['content']['issue_summary']} #{@message['content']['issue_url']}"]
    description << "> #{first_line(@content['comment_body'])}" if @content['event_type'] == 'comment'

    jira_text = team_inbox_event("JIRA", *description)
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, jira_text)
  end

  def valid?
    channel?
  end
end
