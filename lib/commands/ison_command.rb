class IsonCommand < Command
  register_command :ISON

  def set_data(args)
    @data = args
  end

  def valid?
    !!@data && registered?
  end

  def execute!
    available_nicks = []
    ison_nicks = @data.map{|n| n.downcase}
    if !authenticated? and ison_nicks.include? 'nickserv'
      available_nicks << "NickServ"
    elsif authenticated?
      available_nicks = irc_connection.unique_users.map{|u| u.nick}.select{|n| ison_nicks.include? n.downcase}
    end

    reply = render_ison(available_nicks)

    send_reply(reply)
  end
end
