module IrcServer
  FLOWDOCK_DOMAIN = ENV['FLOWDOCK_DOMAIN'] || "flowdock.com"
  HOST = "irc.#{FLOWDOCK_DOMAIN}"
  NAME = "Flowdock IRC Gateway"
  CREATED_AT = Time.now
  NICKSERV_EMAIL ="NickServ@services."
  NICKSERV_HOST = "NickServ!#{NICKSERV_EMAIL}"
  NICKSERV_NAME = "Nickname Services"

  UNKNOWN_USER_EMAIL = "unknown@user.flowdock"
  UNKNOWN_USER_NAME = "User Has Not Authenticated"

  USER_DEFAULT_MODE = "+i"
  CHANNEL_DEFAULT_MODE = "+is"
end
