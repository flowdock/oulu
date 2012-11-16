class SubversionEvent < FlowdockEvent
  register_event "svn"

  def render
    @content = @message['content']

    subversion_text = team_inbox_event(
                  "Subversion",
                  event_string
                )

    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, subversion_text)
  end

  def valid?
    channel?
  end

  private

  def event_string
    case @content['action']
      when 'commit'
        "#{@content['author']['name']} updated '#{@content['repository']['name']}' with #{@content['revision']}: #{@content['message'].split("\n")[0]}"
      when 'branch_create'
        "#{@content['author']['name']} created branch #{@content['branch']} @ #{@content['repository']['name']}"
      when 'branch_delete'
        "#{@content['author']['name']} deleted branch #{@content['branch']} @ #{@content['repository']['name']}"
    end
  end
end
