class JoinCommand < Command
  include AuthenticationHelper
  register_command :JOIN

  def set_data(args)
    @channels = (args.first || "").split(',')
  end

  def valid?
    !!@channels and registered?
  end

  def execute!
    @channels.each do |c|
      if authenticated? && channel = find_channel(c)
        if !channel.open?
          channel.join! do
            send_reply(render_unavailable_resource(channel.irc_id)) if !channel.open?
          end
        end
      else
        send_reply(render_no_such_channel(c))
      end
    end
  end

end
