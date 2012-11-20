class PivotaltrackerEvent < FlowdockEvent
  register_event "pivotaltracker"

  def render
    @content = @message['content']
    description = ["#{@content['description']}"]
    description += @content["stories"].map { |story| "https://www.pivotaltracker.com/story/show/#{story['id']}" }

    pivotal_text = team_inbox_event("Pivotal Tracker", *description)
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, pivotal_text)
  end

  def valid?
    channel?
  end
end
