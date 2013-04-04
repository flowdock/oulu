require 'spec_helper'

describe CommandViews do
  class FakeCommand
    include CommandViews

    def user_irc_host; "Otto!otto@example.com" end
    def user_nick; "Otto"; end
    def user_email; "otto@example.com"; end
    def server_host; "irc.flowdock.com"; end
  end

  before(:all) do
    @cmd = FakeCommand.new
  end

  it "should render notices" do
    @cmd.render_notice("Some!user@somewhere.com", "Otto", "Yo dude").should ==
      ":Some!user@somewhere.com NOTICE Otto :Yo dude"
  end

  it "should render multi-line notices" do
    @cmd.render_notice("Some!user@somewhere.com", "Otto", "Yo dude\nWhazzup").should ==
      ":Some!user@somewhere.com NOTICE Otto :Yo dude\r\n" +
      ":Some!user@somewhere.com NOTICE Otto :Whazzup"
  end

  it "should render MOTD" do
    @cmd.render_welcome.should ==
      ":irc.flowdock.com 001 Otto :Welcome to the Internet Relay Network Otto!otto@example.com"

    @cmd.render_yourhost.should ==
      ":irc.flowdock.com 002 Otto :Your host is irc.flowdock.com, running version 1.0"

    @cmd.render_created.should ==
      ":irc.flowdock.com 003 Otto :This server was created at #{IrcServer::CREATED_AT}"

    @cmd.render_motd_start.should ==
      ":irc.flowdock.com 375 Otto :- irc.flowdock.com Message of the day - "

    @cmd.render_motd_line("Foo bar").should ==
      ":irc.flowdock.com 372 Otto :- Foo bar"

    @cmd.render_motd_end.should ==
      ":irc.flowdock.com 376 Otto :End of MOTD command"
  end

  it "should render my JOIN" do
    @cmd.render_join("#my/channel").should ==
      ":Otto!otto@example.com JOIN :#my/channel"
  end

  it "should render JOIN of another user" do
    @cmd.render_user_join("another!user@example.com", "#my/channel").should ==
      ":another!user@example.com JOIN #my/channel"
  end

  it "should render PART of another user" do
    @cmd.render_user_part("another!user@example.com", "#my/channel").should ==
      ":another!user@example.com PART #my/channel"
  end

  it "should render KICK" do
    @cmd.render_kick("Otto!otto@example.com", "another", "#my/channel").should ==
      ":Otto!otto@example.com KICK #my/channel another"
  end

  it "should render MODE" do
    @cmd.render_mode("Otto!otto@example.com", "Otto", "+i").should ==
      ":Otto!otto@example.com MODE Otto :+i"
  end

  it "should render end of channel ban list" do
    @cmd.render_end_of_ban_list("#my/channel").should ==
      ":irc.flowdock.com 368 Otto #my/channel :End of Channel Ban List"
  end

  it "should render channel modes" do
    @cmd.render_channel_modes("#my/channel", "+is").should ==
      ":irc.flowdock.com 324 Otto #my/channel :+is"
  end

  it "should render NAMES" do
    @cmd.render_names_nicks("#my/channel", ["Otto", "Mikael"]).should ==
      ":irc.flowdock.com 353 Otto @ #my/channel :Otto Mikael"

    @cmd.render_names_end("#my/channel").should ==
      ":irc.flowdock.com 366 Otto #my/channel :End of NAMES list"
  end

  it "should render NICK change" do
    @cmd.render_nick("Otto!otto@example.com", "Newnick").should ==
      ":Otto!otto@example.com NICK :Newnick"
  end

  it "should render NICK error" do
    @cmd.render_nick_error("Newnick").should ==
      ":irc.flowdock.com 432 Otto Newnick :Erroneous nickname"
  end

  it "should render PING" do
    @cmd.render_ping("FOOBAR").should ==
      "PING :FOOBAR"
  end

  it "should render PONG" do
    @cmd.render_pong("BARFOO").should ==
      ":#{IrcServer::HOST} PONG #{IrcServer::HOST} :BARFOO"
  end

  it "should render PRIVMSG" do
    @cmd.render_privmsg("Otto!otto@example.com", "Mikael", "Hello dude").should ==
      ":Otto!otto@example.com PRIVMSG Mikael :Hello dude"

    @cmd.render_privmsg("Otto!otto@example.com", "#my/channel", "Hello channel").should ==
      ":Otto!otto@example.com PRIVMSG #my/channel :Hello channel"
  end

  it "should render multi-line PRIVMSG" do
    @cmd.render_privmsg("Otto!otto@example.com", "Mikael", "Hello dude\nWhazzup").should ==
      ":Otto!otto@example.com PRIVMSG Mikael :Hello dude\r\n" +
      ":Otto!otto@example.com PRIVMSG Mikael :Whazzup"
  end

  it "should render PRIVMSG with ACTION, aka. /me support" do
    @cmd.render_line("Arttu!r2@example.com", "#my/channel", "/me works!").should ==
      ":Arttu!r2@example.com PRIVMSG #my/channel :\u0001ACTION /me works!\u0001"
  end

  it "should render /status as PRIVMSG with ACTION" do
    @cmd.render_status("Arttu!r2@example.com", "#my/channel", "I'll take a short break").should ==
      ":Arttu!r2@example.com PRIVMSG #my/channel :\u0001ACTION changed status to: I'll take a short break\u0001"
  end

  it "should render QUIT" do
    @cmd.render_quit.should ==
      'ERROR :Closing Link: Otto[otto@example.com] ("leaving")'
  end

  it "should render WHOIS user" do
    @cmd.render_whois_user("Mikael", "mikael@example.com", "Mikael Roos").should ==
      ":irc.flowdock.com 311 Otto Mikael mikael example.com * :Mikael Roos"
  end

  it "should render WHOIS channels" do
    @cmd.render_whois_channels("Mikael", "#irc/ottotest #irc/ottomob").should ==
      ":irc.flowdock.com 319 Otto Mikael :#irc/ottotest #irc/ottomob"
  end

  it "should render WHOIS server" do
    @cmd.render_whois_server("Mikael").should ==
      ":irc.flowdock.com 312 Otto Mikael irc.flowdock.com :Flowdock IRC Gateway"
  end

  it "should render WHOIS idle" do
    now = Time.now

    @cmd.render_whois_idle("Mikael", 0, now).should ==
      ":irc.flowdock.com 317 Otto Mikael 0 #{now.to_i} :seconds idle, signon time"
  end

  it "should render WHOIS end" do
    @cmd.render_whois_end("Mikael").should ==
      ":irc.flowdock.com 318 Otto Mikael :End of WHOIS list"
  end

  it "should render WHO entries" do
    @cmd.render_who("#irc/ottotest", "Mikael", "mikael@example.com", "Mikael Roos").should ==
      ":irc.flowdock.com 352 Otto #irc/ottotest mikael example.com irc.flowdock.com Mikael H :0 Mikael Roos"
  end

  it "should render end of WHO list" do
    @cmd.render_who_end("#irc/ottotest").should ==
      ":irc.flowdock.com 315 Otto #irc/ottotest :End of WHO list"
  end

  it "should render error No such nick" do
    @cmd.render_no_such_nick("Foobar").should ==
      ":irc.flowdock.com 401 Otto Foobar :No such nick/channel"
  end

  it "should render response to a new AWAY message" do
    @cmd.render_set_away.should ==
      ":irc.flowdock.com 306 Otto :You have been marked as being away"
  end

  it "should render response to a removed AWAY message" do
    @cmd.render_unset_away.should ==
      ":irc.flowdock.com 305 Otto :You are no longer marked as being away"
  end
end
