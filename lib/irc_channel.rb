require 'uri'

# Each connected user creates a new IrcChannel object for each channel
# they have joined.
class IrcChannel
  # Channel id format: "organization/flow_name"
  attr_accessor :flowdock_id, :web_url, :users
  attr_reader :url, :id

  def initialize(irc_connection, json_hash)
    @id = json_hash["id"].sub("/", ":")
    @irc_connection = irc_connection
    @flowdock_id = parse_id(json_hash["url"])
    @url = json_hash["url"]
    @web_url = json_hash["web_url"]
    @users = init_users(json_hash["users"])
    @name = json_hash["name"]
    @organization_name = json_hash["organization"]
    @open = json_hash["open"]
  end

  def build_message(params = {})
    params.merge(flow: id)
  end

  def irc_id
    '#' + visible_name
  end

  def visible_name
    @flowdock_id
  end

  def topic
    "#{@name} (#{@organization_name})"
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

  def remove_user_by_id(id)
    user = find_user_by_id(id)
    @users.delete(user) if user
  end

  def open?
    @open
  end

  def join!
    @irc_connection.update_flow(self, {open: true}) do
      @irc_connection.update_channel(self) do
        yield if block_given?
      end
    end
  end

  def part!
    @open = false
    @irc_connection.update_flow(self, {open: false}) do
      yield if block_given?
    end
  end

  def to_s
    "<Channel flowdock_id: #{@flowdock_id.inspect}>"
  end

  def update(json_hash)
    @users = init_users(json_hash["users"])
    @open = json_hash["open"]
  end

  protected

  def init_users(hash)
    hash.select { |u| !u["disabled"] }.map do |user|
      User.new(user)
    end
  end

  private

  def parse_id(url)
    path = URI.parse(url).path
    path.split("/")[2..3].join("/")
  end
end
