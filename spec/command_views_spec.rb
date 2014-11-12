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
    expect(@cmd.render_notice("Some!user@somewhere.com", "Otto", "Yo dude")).to eq(
      ":Some!user@somewhere.com NOTICE Otto :Yo dude"
    )
  end

  it "should render multi-line notices" do
    expect(@cmd.render_notice("Some!user@somewhere.com", "Otto", "Yo dude\nWhazzup")).to eq(
      ":Some!user@somewhere.com NOTICE Otto :Yo dude\r\n" +
      ":Some!user@somewhere.com NOTICE Otto :Whazzup"
    )
  end

  it "should render MOTD" do
    expect(@cmd.render_welcome).to eq(
      ":irc.flowdock.com 001 Otto :Welcome to the Internet Relay Network Otto!otto@example.com"
    )

    expect(@cmd.render_yourhost).to eq(
      ":irc.flowdock.com 002 Otto :Your host is irc.flowdock.com, running version 1.0"
    )

    expect(@cmd.render_created).to eq(
      ":irc.flowdock.com 003 Otto :This server was created at #{IrcServer::CREATED_AT}"
    )

    expect(@cmd.render_motd_start).to eq(
      ":irc.flowdock.com 375 Otto :- irc.flowdock.com Message of the day - "
    )

    expect(@cmd.render_motd_line("Foo bar")).to eq(
      ":irc.flowdock.com 372 Otto :- Foo bar"
    )

    expect(@cmd.render_motd_end).to eq(
      ":irc.flowdock.com 376 Otto :End of MOTD command"
    )
  end

  it "should render my JOIN" do
    expect(@cmd.render_join("#my/channel")).to eq(
      ":Otto!otto@example.com JOIN :#my/channel"
    )
  end

  it "should render JOIN of another user" do
    expect(@cmd.render_user_join("another!user@example.com", "#my/channel")).to eq(
      ":another!user@example.com JOIN #my/channel"
    )
  end

  it "should render PART of another user" do
    expect(@cmd.render_user_part("another!user@example.com", "#my/channel")).to eq(
      ":another!user@example.com PART #my/channel"
    )
  end

  it "should render KICK" do
    expect(@cmd.render_kick("Otto!otto@example.com", "another", "#my/channel")).to eq(
      ":Otto!otto@example.com KICK #my/channel another"
    )
  end

  it "should render MODE" do
    expect(@cmd.render_mode("Otto!otto@example.com", "Otto", "+i")).to eq(
      ":Otto!otto@example.com MODE Otto :+i"
    )
  end

  it "should render end of channel ban list" do
    expect(@cmd.render_end_of_ban_list("#my/channel")).to eq(
      ":irc.flowdock.com 368 Otto #my/channel :End of Channel Ban List"
    )
  end

  it "should render channel modes" do
    expect(@cmd.render_channel_modes("#my/channel", "+is")).to eq(
      ":irc.flowdock.com 324 Otto #my/channel :+is"
    )
  end

  it "should render NAMES" do
    expect(@cmd.render_names_nicks("#my/channel", ["Otto", "Mikael"])).to eq(
      ":irc.flowdock.com 353 Otto @ #my/channel :Otto Mikael"
    )

    expect(@cmd.render_names_end("#my/channel")).to eq(
      ":irc.flowdock.com 366 Otto #my/channel :End of NAMES list"
    )
  end

  it "should render NICK change" do
    expect(@cmd.render_nick("Otto!otto@example.com", "Newnick")).to eq(
      ":Otto!otto@example.com NICK :Newnick"
    )
  end

  it "should render NICK error" do
    expect(@cmd.render_nick_error("Newnick")).to eq(
      ":irc.flowdock.com 432 Otto Newnick :Erroneous nickname"
    )
  end

  it "should render PING" do
    expect(@cmd.render_ping("FOOBAR")).to eq(
      "PING :FOOBAR"
    )
  end

  it "should render PONG" do
    expect(@cmd.render_pong("BARFOO")).to eq(
      ":#{IrcServer::HOST} PONG #{IrcServer::HOST} :BARFOO"
    )
  end

  it "should render PRIVMSG" do
    expect(@cmd.render_privmsg("Otto!otto@example.com", "Mikael", "Hello dude")).to eq(
      ":Otto!otto@example.com PRIVMSG Mikael :Hello dude"
    )

    expect(@cmd.render_privmsg("Otto!otto@example.com", "#my/channel", "Hello channel")).to eq(
      ":Otto!otto@example.com PRIVMSG #my/channel :Hello channel"
    )
  end

  it "should render multi-line PRIVMSG" do
    expect(@cmd.render_privmsg("Otto!otto@example.com", "Mikael", "Hello dude\nWhazzup")).to eq(
      ":Otto!otto@example.com PRIVMSG Mikael :Hello dude\r\n" +
      ":Otto!otto@example.com PRIVMSG Mikael :Whazzup"
    )
  end

  it "should render PRIVMSG with ACTION, aka. /me support" do
    expect(@cmd.render_line("Arttu!r2@example.com", "#my/channel", "/me works!")).to eq(
      ":Arttu!r2@example.com PRIVMSG #my/channel :\u0001ACTION /me works!\u0001"
    )
  end

  it "should render /status as PRIVMSG with ACTION" do
    expect(@cmd.render_status("Arttu!r2@example.com", "#my/channel", "I'll take a short break")).to eq(
      ":Arttu!r2@example.com PRIVMSG #my/channel :\u0001ACTION changed status to: I'll take a short break\u0001"
    )
  end

  it "should render QUIT" do
    expect(@cmd.render_quit).to eq(
      'ERROR :Closing Link: Otto[otto@example.com] ("leaving")'
    )
  end

  it "should render WHOIS user" do
    expect(@cmd.render_whois_user("Mikael", "mikael@example.com", "Mikael Roos")).to eq(
      ":irc.flowdock.com 311 Otto Mikael mikael example.com * :Mikael Roos"
    )
  end

  it "should render WHOIS channels" do
    expect(@cmd.render_whois_channels("Mikael", "#irc/ottotest #irc/ottomob")).to eq(
      ":irc.flowdock.com 319 Otto Mikael :#irc/ottotest #irc/ottomob"
    )
  end

  it "should render WHOIS server" do
    expect(@cmd.render_whois_server("Mikael")).to eq(
      ":irc.flowdock.com 312 Otto Mikael irc.flowdock.com :Flowdock IRC Gateway"
    )
  end

  it "should render WHOIS idle" do
    now = Time.now

    expect(@cmd.render_whois_idle("Mikael", 0, now)).to eq(
      ":irc.flowdock.com 317 Otto Mikael 0 #{now.to_i} :seconds idle, signon time"
    )
  end

  it "should render WHOIS end" do
    expect(@cmd.render_whois_end("Mikael")).to eq(
      ":irc.flowdock.com 318 Otto Mikael :End of WHOIS list"
    )
  end

  it "should render WHO entries" do
    expect(@cmd.render_who("#irc/ottotest", "Mikael", "mikael@example.com", "Mikael Roos")).to eq(
      ":irc.flowdock.com 352 Otto #irc/ottotest mikael example.com irc.flowdock.com Mikael H :0 Mikael Roos"
    )
  end

  it "should render end of WHO list" do
    expect(@cmd.render_who_end("#irc/ottotest")).to eq(
      ":irc.flowdock.com 315 Otto #irc/ottotest :End of WHO list"
    )
  end

  it "should render error No such nick" do
    expect(@cmd.render_no_such_nick("Foobar")).to eq(
      ":irc.flowdock.com 401 Otto Foobar :No such nick/channel"
    )
  end

  it "should render response to a new AWAY message" do
    expect(@cmd.render_set_away).to eq(
      ":irc.flowdock.com 306 Otto :You have been marked as being away"
    )
  end

  it "should render response to a removed AWAY message" do
    expect(@cmd.render_unset_away).to eq(
      ":irc.flowdock.com 305 Otto :You are no longer marked as being away"
    )
  end
end
