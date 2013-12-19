class PrivmsgCommand < Command
  include AuthenticationHelper
  register_command :PRIVMSG

  def set_data(args)
    if args.size == 2
      @target = args.first
      @message = args.last
    end
  end

  def valid?
    !!@target && !!@message && registered?
  end

  def execute!
    if !authenticated? && nickserv?
      handle_nickserv!
    else
      if me?
        send_reply(render_privmsg(user_irc_host, @target, @message))
      elsif channel = find_channel(@target)
        if channel.open?
          post_message(channel)
        else
          send_reply(render_cannot_send_to_channel)
        end
      elsif user = find_user(@target)
        post_message(user)
      else
        send_reply(render_no_such_nick(@target))
      end
    end
  end

  protected

  def post_message(target)
    # match to /me command which is actually a PRIVMSG with special format
    if m = @message.match(/^\u0001ACTION (.+)\u0001$/)
      irc_connection.post_status_message(target, m[1])
    else
      irc_connection.post_chat_message(target, @message)
    end
  end

  def handle_nickserv!
    keyword, email, password = @message.split(' ')

    if keyword.downcase == 'identify' && email && password
      authentication_send(email, password)
    end
  end

  def me?
    @target.downcase == user_nick.downcase
  end

  def nickserv?
    @target.downcase == 'nickserv'
  end
end
