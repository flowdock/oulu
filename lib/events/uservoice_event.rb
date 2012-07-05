class UservoicekEvent < FlowdockEvent
  register_event "uservoice"

  def render
    @content = @message['content']

    uservoice_text = team_inbox_event(
                  "Uservoice",
                  *event_strings
                )

    render_notice(IrcServer::FLOWDOCK_USER, @channel.irc_id, uservoice_text)
  end

  private

  def event_strings
    case @content['event']
      when 'new_suggestion'
        suggestion = @content['suggestion']
        [
          "New suggestion: " + suggestion['title'],
          suggestion['url']
        ]
      when 'new_comment'
        comment = @content['comment']
        suggestion = comment['suggestion']
        [
          "New comment on: " + suggestion['title'],
          "> #{first_line(comment['text'])}",
          suggestion['url']
        ]
      when 'new_article'
        article = @content['article']
        [
          "New article: " + article['question'],
          article['url']
        ]
      when 'new_forum'
        forum = @content['forum']
        [
          "New forum: " + forum['name'],
          forum['url']
        ]
      when 'new_kudo'
        kudo = @content['kudo']
        ticket = kudo['ticket']
        [
          kudo['message']['sender']['name'] + " received Kudos! from " + kudo['sender']['name'] + " on " + ticket['subject'],
          ticket['url']
        ]
      when 'new_ticket'
        ticket = @content['ticket']
        [
          "New ticket: " + ticket['subject'],
          ticket['url']
        ]
      when 'new_ticket_reply'
        ticket = @content['ticket']
        [
          "New reply on: " + ticket['subject'],
          ticket['url']
        ]
      when 'suggestion_status_update'
        suggestion = @content['suggestion']
        [
          suggestion['title'] + ": " + suggestion['status']['name'],
          suggestion['url']
        ]
      else
        ["Unknown event"]
    end
  end
end
