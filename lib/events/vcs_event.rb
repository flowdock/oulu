class VcsEvent < FlowdockEvent
  register_event "vcs"

  MAX_COMMITS = 3

  def render
    @content = @message['content']

    rss_text = team_inbox_event(
                  "Github",
                  *event_strings
                )
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, rss_text)
  end

  private

  def event_strings
    case @content['event']
      when 'pull_request'
        if @content['pull_request']['merged'] == true
          github_pull_request('merged')
        else
          github_pull_request(@content['action'])
        end
      when 'issue_comment'
        github_pull_request_comment
      when 'commit_comment'
        github_commit_comment
      when 'push'
        if @content['created'] == true
          github_push_branch('created')
        elsif @content['deleted'] == true
          github_push_branch('deleted')
        else
          github_push
        end
      else # default to push event
        github_push
    end
  end

  def branch
    @content['branch'] || @content['ref'].split('/', 3).last
  end

  def repo_url
    @content['repository']['url']
  end

  def github_push_branch(action)
    "#{@content['pusher']['name']} #{action} branch #{branch} @ #{repo_url}"
  end

  def github_push
    messages = ["#{branch} @ #{repo_url} updated"]
    commits_to_show = (@content['commits'].size == MAX_COMMITS + 1 && MAX_COMMITS + 1 || MAX_COMMITS)
    @content['commits'].reverse.first(commits_to_show).each do |commit|
      commit_hash = (commit['id'] || commit['sha'] || "")
      commit_message = (commit['title'] || commit['message'].split("\n")[0])
      messages << "* #{commit_hash[0..6]}: #{commit_message} <#{commit['author']['email']}>"
    end
    messages << ".. #{(@content['commits'].size - MAX_COMMITS)} more commits .." if @content['commits'].size > MAX_COMMITS + 1
    messages
  end

  def github_commit_comment
    comment = @content['comment']
    [
      "#{comment['user']['login']} commented ##{comment['commit_id'][0..6]} @ #{comment['html_url']}",
      "> #{first_line(comment['body'])}"
    ]
  end

  def github_pull_request(action)
    "#{@content['sender']['login']} #{action} pull request #{@content['pull_request']['issue_url']}"
  end

  def github_pull_request_comment
    comment = @content['comment']
    [
      "#{comment['user']['login']} commented pull request #{@content['issue']['html_url']}",
      "> #{first_line(comment['body'])}"
    ]
  end

  def valid?
    channel?
  end
end
