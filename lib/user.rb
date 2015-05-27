class User
  attr_accessor :id, :nick, :name, :email, :status, :last_activity, :presence, :last_presence_update

  def initialize(hash)
    @id = hash['id'].to_i
    @nick = hash['nick']
    @name = hash['name']
    @email = hash['email']
    @status = hash['status']
    @presence = nil
    @last_presence_update = 0
    update_last_activity(hash['last_activity'])
  end

  def build_message(data = {})
    data.merge(to: @id.to_s)
  end

  def flowdock_id
    @id
  end

  def url
    ApiHelper.api_url("private/#{flowdock_id}")
  end

  def irc_id
    @nick
  end

  def irc_host
    "#{@nick}!#{@email}"
  end

  def update_last_activity(ms_epoch)
    ms_epoch ||= 0
    @last_activity = Time.at(ms_epoch / 1000)
  end

  def active?
    @presence == :active
  end

  def idle?
    @presence == :idle
  end

  def offline?
    @presence == :offline
  end

  def idle_time
    if active?
      0
    elsif idle? || offline?
      Time.now - @last_presence_update
    else
      Time.now - @last_activity
    end
  end
end
