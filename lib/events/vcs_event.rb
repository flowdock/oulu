class VcsEvent < FlowdockEvent
  register_event "vcs"

  def process
    vcs_events = case @message['content']['event']
      when 'pull_request'
        github_pull_request
      else
        github_push
    end

    rss_text = team_inbox_event(
                  "Github",
                  *vcs_events
                )
    text = cmd.send(:render_notice, IrcServer::FLOWDOCK_USER, @channel.irc_id, rss_text)
    @irc_connection.send_reply(text)
  end

  private

  def github_push
    messages = ["#{@message['content']['branch']} @ #{@message['content']['repository']['url']} updated"]
    @message['content']['commits'].reverse.each do |commit|
      messages << "* #{commit['sha'][0..6]}: #{commit['title']} <#{commit['author']['email']}>"
    end
    messages
  end

  def github_pull_request
    "#{@message['content']['sender']['login']} #{@message['content']['action']} pull request #{@message['content']['pull_request']['issue_url']}"
  end
end
