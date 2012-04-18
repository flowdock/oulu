class User
  attr_accessor :id, :nick, :name, :email, :status, :last_activity

  def initialize(hash)
    @id = hash['id'].to_i
    @nick = hash['nick']
    @name = hash['name']
    @email = hash['email']
    @status = hash['status']
    update_last_activity(hash['last_activity'])
  end

  def irc_host
    "#{@nick}!#{@email}"
  end

  def update_last_activity(ms_epoch)
    ms_epoch ||= 0
    @last_activity = Time.at(ms_epoch / 1000)
  end

  def idle_time
    Time.now - @last_activity
  end
end
