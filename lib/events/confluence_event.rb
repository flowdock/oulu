class ConfluenceEvent < FlowdockEvent
  register_event "confluence"
  EVENT_TYPES = {"create" => "created", "delete" => "deleted", "comment_create" => "commented", "update" => "updated"}

  def render
    @content = @message['content']
    action = EVENT_TYPES[@content['event']]
    return if action.nil?

    description = ["#{@content['user_name']} #{action} page in #{@message['content']['space_name']}: #{@message['content']['page_title']}"]
    description[0] += " #{@message['content']['page_url']}" unless @content['event'] == 'delete'
    description << "> #{first_line(@content['comment_content_summary'])}" if @content['event'] == 'comment_create'

    confluence_text = team_inbox_event("Confluence", *description)
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, confluence_text)
  end

  def valid?
    channel?
  end
end
