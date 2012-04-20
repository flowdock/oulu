class VcsEvent < FlowdockEvent
  register_event "vcs"

  def process
    vcs_events = ["#{@message['content']['branch']} @ #{@message['content']['repository']['url']} updated"]
    @message['content']['commits'].reverse.each do |commit|
      vcs_events << "* #{commit['sha'][0..6]}: #{commit['title']} <#{commit['author']['email']}>"
    end

    rss_text = team_inbox_event(
                  "Github",
                  *vcs_events
                )
    text = cmd.send(:render_notice, IrcServer::FLOWDOCK_USER, @channel.irc_id, rss_text)
    @irc_connection.send_reply(text)
  end
end
