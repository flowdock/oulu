require 'spec_helper'

describe FlowdockEvent do
  before(:each) do
    @irc_connection = mock(:irc_connection)
    @flow_hash = Yajl::Parser.parse(fixture('flows')).first

    @channel = IrcChannel.new(@irc_connection, @flow_hash)
  end

  describe "with parsing events" do
    before(:each) do
      @irc_connection.should_receive(:find_channel).with("irc:ottotest").and_return(@channel)
    end

    it "should process standard chat message" do
      message_event = message_hash('message_event')
      @irc_connection.should_receive(:remove_outgoing_message).with(message_event).and_return(false)

      @irc_connection.should_receive(:send_reply).with(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      event.process
    end

    it "should render standard chat message" do
      message_event = message_hash('message_event')

      event = FlowdockEvent.from_message(@irc_connection, message_event)
      event.render.should == ":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :test"
    end

    describe "action events" do
      it "should handle join event" do
        join_message = message_hash('join_event')
        fake_channel_users_update([{"id" => join_message["user"], "nick" => "test", "email" => "test@example.com"}])

        event = FlowdockEvent.from_message(@irc_connection, join_message)
        event.render.should == ":test!test@example.com JOIN #{@channel.irc_id}"
      end

      it "should render block event" do
        event = FlowdockEvent.from_message(@irc_connection, message_hash('block_event'))
        event.render.should == ":Otto!otto@example.com KICK #{@channel.irc_id} Ottomob"
      end

      it "should render add_people event" do
        add_people_message = message_hash('add_people_event')
        fake_channel_users_update([{"id" => 100, "nick" => add_people_message["content"]["message"].first, "email" => "test@example.com"},
          {"id" => 101, "nick" => add_people_message["content"]["message"].last, "email" => "foobar@example.com"}])

        event = FlowdockEvent.from_message(@irc_connection, add_people_message)
        event.render.should == [
            ":test!test@example.com JOIN #{@channel.irc_id}",
            ":foobar!foobar@example.com JOIN #{@channel.irc_id}"
          ].join("\r\n")
      end
    end

    it "should render comment event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('comment_event'))
      event.render.should == ":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :[Team inbox item's title] << test"
    end

    it "should handle line event (/me in desktop Flowdock)" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('line_event'))
      event.render.should == ":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :\u0001ACTION test\u0001"
    end

    it "should handle status event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('status_event'))
      event.render.should == ":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :\u0001ACTION changed status to: uusin status\u0001"
    end

    it "should render file event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('file_event'))
      event.render.should == ":Otto!otto@example.com PRIVMSG #irc/ottotest :https://irc.flowdock.com/flows/irc/ottotest/files/Sse2n5VKLlLeafMsjFLuxA/globe.rb"
    end

    describe "team inbox messages" do
      {
        "email" => [
            "[Email] This is the email subject <arttu.tervo@gmail.com>",
            "[Email] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/2182",
          ],
        "rss" => [
            "[RSS] [[Satisfaction]: New topics and replies for Word]: New reply: \"Freezing Tiles\"",
            "[RSS] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/123367",
          ],
        "vcs:github/push_new_branch" => [
            "[Github] testfoe created branch new-branch @ https://github.com/testfoe/API-test",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/148056",
          ],
        "vcs:github/push_delete_branch" => [
            "[Github] testfoe deleted branch stupid-feature @ https://github.com/testfoe/API-test",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/148113",
          ],
        "vcs:github/push" => [
            "[Github] master @ https://github.com/flowdock/oulu updated",
            "[Github] * b2c2857: Merge branch 'master' of github.com:flowdock/oulu <tuomas.silen@nodeta.fi>",
            "[Github] * c70bcf7: Support ISON command for NickServ <tuomas.silen@nodeta.fi>",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/5706106",
          ],
        "vcs:github/push_large" => [
            "[Github] master @ https://github.com/testfoe/API-test updated",
            "[Github] * 22d38bd: Merge pull request #3 from testfoe/new-feature <testfoe@example.com>",
            "[Github] * 6db2b04: More descriptive readme <testfoe@example.com>",
            "[Github] * 6db2b04: More descriptive readme <testfoe@example.com>",
            "[Github] .. 2 more commits ..",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/147958",
          ],
        "vcs:github/commit_comment" => [
            "[Github] testfoe commented #22d38bd @ https://github.com/testfoe/API-test/commit/22d38bdc5f#commitcomment-666757",
            "[Github] > This is the comment body.",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/148005",
          ],
        "vcs:github/pull_request_open" => [
            "[Github] arttu opened pull request https://github.com/flowdock/flowdock-web/issues/190",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/5706152",
          ],
        "vcs:github/pull_request_merge" => [
            "[Github] testfoe merged pull request https://github.com/testfoe/API-test/issues/3",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/148184",
          ],
        "vcs:github/pull_request_close" => [
            "[Github] testfoe closed pull request https://github.com/testfoe/API-test/issues/4",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/148175",
          ],
        "vcs:github/pull_request_comment" => [
            "[Github] testfoe commented pull request https://github.com/testfoe/API-test/issues/3",
            "[Github] > Commenting pull request. More text is better since then we can see how the UI scales. And other things of that nature. Just like Arnold Schwarzenegger would say.",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/148150",
          ],
      }.each_pair do |_event, content|
        event, fixture = (_event.match(':') && _event.split(':') || [_event, _event])

        it "should render #{_event} event" do
          prefix = ":#{IrcServer::FLOWDOCK_USER} NOTICE #{@channel.irc_id} :"
          event = FlowdockEvent.from_message(@irc_connection, message_hash("#{fixture}_event"))
          event.render.should == "#{prefix}#{content.join("\r\n#{prefix}")}"
        end
      end
    end
  end

  def fake_channel_users_update(users)
    # fake updating channel users
    users.each { |user| @flow_hash["users"] << user }
    @channel.update(@flow_hash)
  end

  def message_hash(event)
    Yajl::Parser.parse(fixture("flowdock_events/#{event}"))
  end
end
