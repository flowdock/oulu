class User
  attr_accessor :id, :nick, :name, :email, :status

  def initialize(hash)
    @id = hash['id'].to_i
    @nick = hash['nick']
    @name = hash['name']
    @email = hash['email']
    @status = hash['status']
  end

  def irc_host
    "#{@nick}!#{@email}"
  end
end
