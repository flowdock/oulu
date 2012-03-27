# Each connected user creates a new IrcChannel object for each channel
# they have joined.
class IrcChannel
  # Channel id format: "organization/flow_name"
  attr_accessor :flowdock_id, :web_url, :users

  def initialize(irc_connection, json_hash)
    @irc_connection = irc_connection
    @flowdock_id = json_hash["id"]
    @web_url = json_hash["web_url"]
    @users = init_users(json_hash["users"])
  end

  def irc_id
    '#' + @flowdock_id
  end

  def receive_message(message)
  end

  def find_user_by_id(id)
    @users.detect do |user|
      user.id == id.to_i
    end
  end

  def find_user_by_nick(nick)
    return nil unless nick
    nick_downcase = nick.downcase

    @users.detect do |user|
      user.nick.downcase == nick_downcase
    end
  end

  def to_s
    "<Channel flowdock_id: #{@flowdock_id.inspect}>"
  end

  protected

  def init_users(hash)
    hash.select { |u| !u["disabled"] }.map do |user|
      User.new(user)
    end
  end
end
