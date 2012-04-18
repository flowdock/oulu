class RssEvent < FlowdockEvent
  register_event "rss"

  def process
    rss_text = [
      "[Rss] [#{@message['content']['feed']['title']}]: #{@message['content']['title']}",
    ].push(
        team_inbox_link("Rss", @message['id'])
      ).join("\n")

    text = cmd.send(:render_notice, IrcServer::FLOWDOCK_USER, @channel.irc_id, rss_text)
    @irc_connection.send_reply(text)
  end
end
