class MessageEditEvent < FlowdockEvent
  register_event "message-edit"

  MESSAGE_EDIT_THRESHOLD_IN_SECONDS =  60

  def process
    resource = @target.url + "/messages/#{message_id}"
    http = ApiHelper.new(@irc_connection.email, @irc_connection.password).get(resource)

    http.callback do
      if http.response_header.status == 200
        response = MultiJson.load(http.response)
        render!(response) if fresh?(response)
      else
        $logger.error "Message edit: Got #{http.response_header.status} when issuing: #{resource}"
      end
    end

    http.errback do
      $logger.error "Message edit: Could not get message with id #{message_id}"
    end
  end

  def valid?
    !!@target && !!@user
  end

  private

  def message_id
    @message['content']['message']
  end

  def fresh?(response)
    Time.now.to_i - response['sent'] / 1000 < MESSAGE_EDIT_THRESHOLD_IN_SECONDS
  end

  def render!(response)
    content = case response['event']
              when 'message' then @message['content']['updated_content']
              when 'comment'
                updated_content = @message['content']['updated_content']
                "[#{updated_content['title']}] << #{updated_content['text']}"
              end

    return unless content
    text = render_privmsg(@user.irc_host, @target.irc_id, content + "*")
    @irc_connection.send_reply(text)
  end
end

