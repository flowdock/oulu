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
      @irc_connection.should_receive(:find_user_by_id).once do |arg|
        @channel.find_user_by_id(arg)
      end
    end

    it "should process standard chat message" do
      message_event = message_hash('message_event')
      @irc_connection.should_receive(:remove_outgoing_message).with(message_event).and_return(false)

      @irc_connection.should_receive(:send_reply).with(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      event.valid?.should be_true
      event.process
    end

    it "should process standard chat message from external user" do
      message_event = message_hash('message_from_external_user_event')
      @irc_connection.should_receive(:remove_outgoing_message).with(message_event).and_return(false)

      @irc_connection.should_receive(:send_reply).with(":Robot!unknown@user.flowdock PRIVMSG #{@channel.irc_id} :test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      event.valid?.should be_true
      event.process
    end

    it "should validate external user in chat messages" do
      message_event = message_hash('message_from_external_user_event')
      message_event['external_user_name'] += ':!@'
      @irc_connection.should_receive(:remove_outgoing_message).with(message_event).and_return(false)

      @irc_connection.should_receive(:send_reply).with(":Robot___!unknown@user.flowdock PRIVMSG #{@channel.irc_id} :test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      event.valid?.should be_true
      event.process
    end

    it "should render standard chat message" do
      message_event = message_hash('message_event')

      event = FlowdockEvent.from_message(@irc_connection, message_event)
      event.valid?.should be_true
      event.render.should == ":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :test"
    end

    describe "action events" do
      it "should handle join event" do
        join_message = message_hash('join_event')
        fake_channel_users_update([{"id" => join_message["user"], "nick" => "test", "email" => "test@example.com"}])

        event = FlowdockEvent.from_message(@irc_connection, join_message)
        event.valid?.should be_true
        event.render.should == ":test!test@example.com JOIN #{@channel.irc_id}"
      end

      it "should render block event" do
        event = FlowdockEvent.from_message(@irc_connection, message_hash('block_event'))
        event.valid?.should be_true
        event.render.should == ":Otto!otto@example.com KICK #{@channel.irc_id} Ottomob"
      end

      it "should render add_people event" do
        add_people_message = message_hash('add_people_event')
        fake_channel_users_update([{"id" => 100, "nick" => add_people_message["content"]["message"].first, "email" => "test@example.com"},
          {"id" => 101, "nick" => add_people_message["content"]["message"].last, "email" => "foobar@example.com"}])

        event = FlowdockEvent.from_message(@irc_connection, add_people_message)
        event.valid?.should be_true
        event.render.should == [
            ":test!test@example.com JOIN #{@channel.irc_id}",
            ":foobar!foobar@example.com JOIN #{@channel.irc_id}"
          ].join("\r\n")
      end
    end

    it "should render comment event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('comment_event'))
      event.valid?.should be_true
      event.render.should == ":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :[Team inbox item's title] << test"
    end

    it "should handle line event (/me in desktop Flowdock)" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('line_event'))
      event.valid?.should be_true
      event.render.should == ":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :\u0001ACTION test\u0001"
    end

    it "should handle status event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('status_event'))
      event.valid?.should be_true
      event.render.should == ":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :\u0001ACTION changed status to: uusin status\u0001"
    end

    it "should render file event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('file_event'))
      event.valid?.should be_true
      event.render.should == ":Otto!otto@example.com PRIVMSG #irc/ottotest :https://irc.flowdock.com/flows/irc/ottotest/files/Sse2n5VKLlLeafMsjFLuxA/globe.rb"
    end

    describe "team inbox messages" do
      {
        "email" => [
            "[Email] arttu.tervo@gmail.com: This is the email subject",
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
        "vcs:github/push_semi_large" => [
            "[Github] master @ https://github.com/testfoe/API-test updated",
            "[Github] * 22d38bd: Merge pull request #3 from testfoe/new-feature <testfoe@example.com>",
            "[Github] * 6db2b04: More descriptive readme <testfoe@example.com>",
            "[Github] * 6db2b04: More descriptive readme <testfoe@example.com>",
            "[Github] * 6db2b04: This is the fourth commit in this push <testfoe@example.com>",
            "[Github] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/147958",
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
        "svn:subversion/commit" => [
            "[Subversion] arttutervo updated 'foo' with r1: Svn directory structure.",
            "[Subversion] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/1234567",
          ],
        "svn:subversion/multiline_commit" => [
            "[Subversion] arttutervo updated 'foo' with r2: Added a README,",
            "[Subversion] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/1234570",
          ],
        "svn:subversion/branch_create" => [
            "[Subversion] arttutervo created branch ultimate @ foo",
            "[Subversion] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/1234568",
          ],
        "svn:subversion/branch_delete" => [
            "[Subversion] arttutervo deleted branch ultimate @ foo",
            "[Subversion] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/1234569",
          ],
        "jira:jira/create" => [
            "[JIRA] Otto Hilska created issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5",
            "[JIRA] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/36",
          ],
        "jira:jira/update" => [
            "[JIRA] Otto Hilska updated issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5",
            "[JIRA] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/57",
          ],
        "jira:jira/resolve" => [
            "[JIRA] Ville Lautanala resolved issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5",
            "[JIRA] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/64",
          ],
        "jira:jira/close" => [
            "[JIRA] Otto Hilska closed issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5",
            "[JIRA] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/46",
          ],
        "jira:jira/comment" => [
            "[JIRA] Ville Lautanala commented issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5",
            "[JIRA] > Now that I'm working on this, this is simply a comment (no editing involved).",
            "[JIRA] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/70",
          ],
        "jira:jira/start_work" => [
            "[JIRA] Ville Lautanala started working on issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5",
            "[JIRA] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/75",
          ],
        "confluence:confluence/create" => [
            "[Confluence] admin created page in Demonstration Space: Some page http://localhost:1990/confluence/display/ds/Somepage",
            "[Confluence] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/220",
          ],
        "confluence:confluence/update" => [
            "[Confluence] admin updated page in Demonstration Space: Home http://localhost:1990/confluence/display/ds/Home",
            "[Confluence] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/1277",
          ],
        "confluence:confluence/delete" => [
            "[Confluence] admin deleted page in Demonstration Space: Some page",
            "[Confluence] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/199",
          ],
        "confluence:confluence/comment_create" => [
            "[Confluence] mutru commented page in Demonstration Space: Home http://localhost:1990/confluence/display/ds/Home",
            "[Confluence] > Test comment",
            "[Confluence] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/1280",
          ],
        "uservoice:uservoice/suggestion" => [
            "[Uservoice] New suggestion: Test suggestion",
            "[Uservoice] http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion",
            "[Uservoice] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/48828"
          ],
        "uservoice:uservoice/comment" => [
            "[Uservoice] New comment on: Test suggestion",
            "[Uservoice] > Test comment",
            "[Uservoice] http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion",
            "[Uservoice] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/48918"
          ],
        "uservoice:uservoice/article" => [
            "[Uservoice] New article: Is this a new article?",
            "[Uservoice] http://test.uservoice.com/knowledgebase/articles/-is-this-a-new-article-",
            "[Uservoice] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/50045"
          ],
        "uservoice:uservoice/forum" => [
            "[Uservoice] New forum: Test forum",
            "[Uservoice] http://test.uservoice.com/forums/-test-forum",
            "[Uservoice] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/50051"
          ],
        "uservoice:uservoice/kudo" => [
            "[Uservoice] Test Message Sender received Kudos! from Test Kudo Sender on Test subject",
            "[Uservoice] http://test.uservoice.com/admin/tickets/1",
            "[Uservoice] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/50066"
          ],
        "uservoice:uservoice/suggestion_status_changed" => [
            "[Uservoice] Test suggestion: completed",
            "[Uservoice] http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion",
            "[Uservoice] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/50079"
          ],
        "uservoice:uservoice/ticket" => [
            "[Uservoice] New ticket: Test subject",
            "[Uservoice] http://test.uservoice.com/admin/tickets/1",
            "[Uservoice] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/50085"
          ],
        "uservoice:uservoice/ticket_reply" => [
            "[Uservoice] New reply on: Test subject",
            "[Uservoice] http://test.uservoice.com/admin/tickets/1",
            "[Uservoice] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/50091"
          ],
        "pivotaltracker:pivotaltracker/story_create" => [
            "[Pivotal Tracker] Otto Hilska added \"The greatest story ever\"",
            "[Pivotal Tracker] https://www.pivotaltracker.com/story/show/7877517",
            "[Pivotal Tracker] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/1431",
          ],
        "pivotaltracker:pivotaltracker/multi_story_edit" => [
            "[Pivotal Tracker] Otto Hilska edited 3 stories",
            "[Pivotal Tracker] https://www.pivotaltracker.com/story/show/6363057",
            "[Pivotal Tracker] https://www.pivotaltracker.com/story/show/6363061",
            "[Pivotal Tracker] https://www.pivotaltracker.com/story/show/7877517",
            "[Pivotal Tracker] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/1474",
          ],
        "twitter" => [
            "[Twitter] FlowdockRumors: /server -ssl http://t.co/wGqvQmbP 6697",
            "[Twitter] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/153642",
          ],
        "twitter:multiline_tweet" => [
            "[Twitter] FlowdockRumors: /server -ssl http://t.co/wGqvQmbP 6697",
            "KICK Otto",
            "[Twitter] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/153642",
          ],
        "zendesk" => [
            "[Zendesk] Arttu Tervo commented ticket",
            "[Zendesk] http://testcompany.zendesk.com/tickets/2",
            "[Zendesk] Show in Flowdock: https://irc.#{IrcServer::FLOWDOCK_DOMAIN}/flows/ottotest#/influx/show/173643",
          ],
      }.each_pair do |_event, content|
        event, fixture = (_event.match(':') && _event.split(':') || [_event, _event])

        it "should render #{_event} event" do
          prefix = ":#{IrcServer::FLOWDOCK_USER} NOTICE #{@channel.irc_id} :"
          event = FlowdockEvent.from_message(@irc_connection, message_hash("#{fixture}_event"))
          event.valid?.should be_true
          event.render.should == "#{prefix}#{content.join("\r\n#{prefix}")}"
        end

        it "should not be valid as private events" do
          event = FlowdockEvent.from_message(@irc_connection, message_hash("#{fixture}_event"))
          event.stub!(:channel?).and_return(false)
          event.valid?.should be_false
        end
      end
    end
  end

  describe "private message parsing" do
    before(:each) do
      target_user = @channel.find_user_by_id("50000")
      sender = @channel.find_user_by_id("1")
      @irc_connection.should_receive(:find_user_by_id).with("50000").once.and_return(target_user)
      @irc_connection.should_receive(:find_user_by_id).with("1").once.and_return(sender)
    end

    it "should process private chat message" do
      message_event = message_hash('private_message')
      @irc_connection.should_receive(:remove_outgoing_message).with(message_event).and_return(false)

      @irc_connection.should_receive(:send_reply).with(":Otto!otto@example.com PRIVMSG Ottomob :private test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      event.valid?.should be_true
      event.process
    end

    it "should render private chat message" do
      message_event = message_hash('private_message')

      event = FlowdockEvent.from_message(@irc_connection, message_event)
      event.valid?.should be_true
      event.render.should == ":Otto!otto@example.com PRIVMSG Ottomob :private test"
    end
  end

  describe "message editing" do
    before :each do
      @irc_connection.should_receive(:find_channel).with("irc:ottotest").and_return(@channel)
      sender = @channel.find_user_by_id("1")
      @irc_connection.should_receive(:find_user_by_id).with("1").once.and_return(sender)
    end

    it "should process message edit event" do
      message_event = message_hash("message_edit_event")
      @irc_connection.should_receive(:send_reply).with(":Otto!otto@example.com PRIVMSG #irc/ottotest :updated test message*")

      event = FlowdockEvent.from_message(@irc_connection, message_event)
      event.valid?.should be_true
      event.process
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
