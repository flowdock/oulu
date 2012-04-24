class PivotaltrackerEvent < FlowdockEvent
  register_event "pivotaltracker"

  def process
    @content = @message['content']
    description = ["#{@content['description']}"]
    description |= @content["stories"].map { |story| story["url"] }

    pivotal_text = team_inbox_event("Pivotal Tracker", *description)
    text = cmd.send(:render_notice, IrcServer::FLOWDOCK_USER, @channel.irc_id, pivotal_text)
    @irc_connection.send_reply(text)
  end
end
