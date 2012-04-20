class VcsEvent < FlowdockEvent
  register_event "vcs"

  MAX_COMMITS = 3

  def process
    vcs_events = case @message['content']['event']
      when 'pull_request'
        if @message['content']['pull_request']['merged'] == true
          github_pull_request('merged')
        else
          github_pull_request(@message['content']['action'])
        end
      when 'issue_comment'
        github_pull_request_comment
      when 'commit_comment'
        github_commit_comment
      when 'push'
        if @message['content']['created'] == true
          github_push_branch('created')
        elsif @message['content']['deleted'] == true
          github_push_branch('deleted')
        else
          github_push
        end
      else # default to push event
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

  def branch
    @message['content']['branch'] || @message['content']['ref'].split('/', 3).last
  end

  def repo_url
    @message['content']['repository']['url']
  end

  def first_line(text)
    text.split(/\\?\\n/)[0] # find out if the actual line feeds are escaped "\\n" or non-escaped "\n" here
  end

  def github_push_branch(action)
    "#{@message['content']['pusher']['name']} #{action} branch #{branch} @ #{repo_url}"
  end

  def github_push
    messages = ["#{branch} @ #{repo_url} updated"]
    @message['content']['commits'].reverse.first(MAX_COMMITS).each do |commit|
      commit_hash = (commit['id'] || commit['sha'] || "")
      commit_message = (commit['title'] || commit['message'].split("\n")[0])
      messages << "* #{commit_hash[0..6]}: #{commit_message} <#{commit['author']['email']}>"
    end
    messages << ".. #{(@message['content']['commits'].size - MAX_COMMITS)} more commits .." if @message['content']['commits'].size > MAX_COMMITS
    messages
  end

  def github_commit_comment
    comment = @message['content']['comment']
    [
      "#{comment['user']['login']} commented ##{comment['commit_id'][0..6]} @ #{comment['html_url']}",
      "> #{first_line(comment['body'])}"
    ]
  end

  def github_pull_request(action)
    "#{@message['content']['sender']['login']} #{action} pull request #{@message['content']['pull_request']['issue_url']}"
  end

  def github_pull_request_comment
    comment = @message['content']['comment']
    [
      "#{comment['user']['login']} commented pull request #{@message['content']['issue']['html_url']}",
      "> #{first_line(comment['body'])}"
    ]
  end
end
