class MessageProcessor
  def initialize message
    @message = message
  end

  def perform
    if Hash === @message['content']
      if @message['content']['text']
        @message['content']['text'] = strip_emoji @message['content']['text']
      end

      if @message['content']['title']
        @message['content']['title'] = strip_emoji @message['content']['title']
      end
    elsif String === @message['content']
      @message['content'] = strip_emoji @message['content']
    end

    @message
  end

  private

  # Convert emoji characters to text represnation so
  # terminals/irc clients which do not support emoji still show whole message
  def strip_emoji content
    EmojiCleaner.perform content
  end
end
