require 'spec_helper'

describe FlowdockEvent do
  before(:each) do
    @irc_connection = double(:irc_connection)
    @flow_hash = Yajl::Parser.parse(fixture('flows')).first
    @channel = IrcChannel.new(@irc_connection, @flow_hash)
  end

  describe "with parsing events" do
    before(:each) do
      expect(@irc_connection).to receive(:find_channel_by_id).with("irc:ottotest").and_return(@channel)
      expect(@irc_connection).to receive(:find_user_by_id).once do |arg|
        @channel.find_user_by_id(arg)
      end
    end

    it "should process standard chat message" do
      message_event = message_hash('message_event')
      expect(@irc_connection).to receive(:remove_outgoing_message).with(message_event).and_return(false)

      expect(@irc_connection).to receive(:send_reply).with(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :<907> test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      event.process
    end

    it "should process legacy chat message" do
      message_event = message_hash('legacy_message_event')
      expect(@irc_connection).to receive(:remove_outgoing_message).with(message_event).and_return(false)

      expect(@irc_connection).to receive(:send_reply).with(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :<907> test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      event.process
    end

    it "should process standard chat message from external user" do
      message_event = message_hash('message_from_external_user_event')
      expect(@irc_connection).to receive(:remove_outgoing_message).with(message_event).and_return(false)

      expect(@irc_connection).to receive(:send_reply).with(":Robot!unknown@user.flowdock PRIVMSG #{@channel.irc_id} :<907> test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      event.process
    end

    it "should validate external user in chat messages" do
      message_event = message_hash('message_from_external_user_event')
      message_event['external_user_name'] += ':!@'
      expect(@irc_connection).to receive(:remove_outgoing_message).with(message_event).and_return(false)

      expect(@irc_connection).to receive(:send_reply).with(":Robot___!unknown@user.flowdock PRIVMSG #{@channel.irc_id} :<907> test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      event.process
    end

    it "should render standard chat message" do
      message_event = message_hash('message_event')

      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      expect(event.render).to eq(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :<907> test")
    end

    it "should render legacy chat message" do
      message_event = message_hash('legacy_message_event')

      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      expect(event.render).to eq(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :<907> test")
    end

    it "should render chat message belonging to thread" do
      thread_message_event = message_hash("thread_message_event")

      event = FlowdockEvent.from_message(@irc_connection, thread_message_event)
      expect(event).to be_valid
      expect(event.render).to eq(": PRIVMSG #irc/ottotest :[Oulu Test app (Test source): Test acticity] <388467> << And I'm commenting to this")
    end

    it "should decode and render emoji in standard chat message" do
      message_event = message_hash('message_event_emoji')

      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      expect(event.render).to eq(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :<907> test :rage:")
    end

    describe "action events" do
      it "should handle join event" do
        join_message = message_hash('join_event')
        fake_channel_users_update([{"id" => join_message["user"], "nick" => "test", "email" => "test@example.com"}])

        event = FlowdockEvent.from_message(@irc_connection, join_message)
        expect(event).to be_valid
        expect(event.render).to eq(":test!test@example.com JOIN #{@channel.irc_id}")
      end

      it "should render add_people event" do
        original_user_ids = @channel.users.map(&:id)
        add_people_message = message_hash('add_people_event')
        fake_channel_users_update([{"id" => 100, "nick" => add_people_message["content"]["message"].first, "email" => "test@example.com"},
          {"id" => 101, "nick" => add_people_message["content"]["message"].last, "email" => "foobar@example.com"}])

        event = FlowdockEvent.from_message(@irc_connection, add_people_message)
        event.instance_variable_set(:@original_user_ids, original_user_ids)
        expect(event).to be_valid
        expect(event.render).to eq([
            ":test!test@example.com JOIN #{@channel.irc_id}",
            ":foobar!foobar@example.com JOIN #{@channel.irc_id}"
          ].join("\r\n"))
      end
    end

    it "should render block event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('block_event'))
      expect(event).to be_valid
      expect(event.render).to eq(":Ottomob!ottomob@example.com PART #{@channel.irc_id}")
    end

    it "should render comment event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('comment_event'))
      expect(event).to be_valid
      expect(event.render).to eq(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :[Team inbox item's title] << test")
    end

    it "should handle line event (/me in desktop Flowdock)" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('line_event'))
      expect(event).to be_valid
      expect(event.render).to eq(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :\u0001ACTION test\u0001")
    end

    it "should handle status event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('status_event'))
      expect(event).to be_valid
      expect(event.render).to eq(":Otto!otto@example.com PRIVMSG #{@channel.irc_id} :\u0001ACTION changed status to: uusin status\u0001")
    end

    it "should render file event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('file_event'))
      expect(event).to be_valid
      expect(event.render).to eq(":Otto!otto@example.com PRIVMSG #irc/ottotest :https://www.flowdock.com/rest/flows/irc/ottotest/files/Sse2n5VKLlLeafMsjFLuxA/globe.rb")
    end

    describe "team inbox messages" do
      {
        "email" => [
            "[Email] arttu.tervo@gmail.com: This is the email subject"
          ],
        "rss" => [
            "[RSS] [[Satisfaction]: New topics and replies for Word]: New reply: \"Freezing Tiles\""
          ],
        "vcs:github/push_new_branch" => [
            "[Github] testfoe created branch new-branch @ https://github.com/testfoe/API-test"
          ],
        "vcs:github/push_delete_branch" => [
            "[Github] testfoe deleted branch stupid-feature @ https://github.com/testfoe/API-test"
          ],
        "vcs:github/push" => [
            "[Github] master @ https://github.com/flowdock/oulu updated",
            "[Github] * b2c2857: Merge branch 'master' of github.com:flowdock/oulu <tuomas.silen@nodeta.fi>",
            "[Github] * c70bcf7: Support ISON command for NickServ <tuomas.silen@nodeta.fi>"
          ],
        "vcs:github/push_semi_large" => [
            "[Github] master @ https://github.com/testfoe/API-test updated",
            "[Github] * 22d38bd: Merge pull request #3 from testfoe/new-feature <testfoe@example.com>",
            "[Github] * 6db2b04: More descriptive readme <testfoe@example.com>",
            "[Github] * 6db2b04: More descriptive readme <testfoe@example.com>",
            "[Github] * 6db2b04: This is the fourth commit in this push <testfoe@example.com>"
          ],
        "vcs:github/push_large" => [
            "[Github] master @ https://github.com/testfoe/API-test updated",
            "[Github] * 22d38bd: Merge pull request #3 from testfoe/new-feature <testfoe@example.com>",
            "[Github] * 6db2b04: More descriptive readme <testfoe@example.com>",
            "[Github] * 6db2b04: More descriptive readme <testfoe@example.com>",
            "[Github] .. 2 more commits .."
          ],
        "vcs:github/commit_comment" => [
            "[Github] testfoe commented #22d38bd @ https://github.com/testfoe/API-test/commit/22d38bdc5f#commitcomment-666757",
            "[Github] > This is the comment body."
          ],
        "vcs:github/pull_request_open" => [
            "[Github] arttu opened pull request https://github.com/flowdock/flowdock-web/issues/190"
          ],
        "vcs:github/pull_request_merge" => [
            "[Github] testfoe merged pull request https://github.com/testfoe/API-test/issues/3"
          ],
        "vcs:github/pull_request_close" => [
            "[Github] testfoe closed pull request https://github.com/testfoe/API-test/issues/4"
          ],
        "vcs:github/pull_request_comment" => [
            "[Github] testfoe commented pull request https://github.com/testfoe/API-test/issues/3",
            "[Github] > Commenting pull request. More text is better since then we can see how the UI scales. And other things of that nature. Just like Arnold Schwarzenegger would say."
          ],
        "svn:subversion/commit" => [
            "[Subversion] arttutervo updated 'foo' with r1: Svn directory structure."
          ],
        "svn:subversion/multiline_commit" => [
            "[Subversion] arttutervo updated 'foo' with r2: Added a README,"
          ],
        "svn:subversion/branch_create" => [
            "[Subversion] arttutervo created branch ultimate @ foo"
          ],
        "svn:subversion/branch_delete" => [
            "[Subversion] arttutervo deleted branch ultimate @ foo"
          ],
        "jira:jira/create" => [
            "[JIRA] Otto Hilska created issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5"
          ],
        "jira:jira/update" => [
            "[JIRA] Otto Hilska updated issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5"
          ],
        "jira:jira/resolve" => [
            "[JIRA] Ville Lautanala resolved issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5"
          ],
        "jira:jira/close" => [
            "[JIRA] Otto Hilska closed issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5"
          ],
        "jira:jira/comment" => [
            "[JIRA] Ville Lautanala commented issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5",
            "[JIRA] > Now that I'm working on this, this is simply a comment (no editing involved)."
          ],
        "jira:jira/start_work" => [
            "[JIRA] Ville Lautanala started working on issue: Otto's new bug http://localhost:2990//jira/browse/TEST-5"
          ],
        "confluence:confluence/create" => [
            "[Confluence] admin created page in Demonstration Space: Some page http://localhost:1990/confluence/display/ds/Somepage"
          ],
        "confluence:confluence/update" => [
            "[Confluence] admin updated page in Demonstration Space: Home http://localhost:1990/confluence/display/ds/Home"
          ],
        "confluence:confluence/delete" => [
            "[Confluence] admin deleted page in Demonstration Space: Some page"
          ],
        "confluence:confluence/comment_create" => [
            "[Confluence] mutru commented page in Demonstration Space: Home http://localhost:1990/confluence/display/ds/Home",
            "[Confluence] > Test comment"
          ],
        "uservoice:uservoice/suggestion" => [
            "[Uservoice] New suggestion: Test suggestion",
            "[Uservoice] http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion"
          ],
        "uservoice:uservoice/comment" => [
            "[Uservoice] New comment on: Test suggestion",
            "[Uservoice] > Test comment",
            "[Uservoice] http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion"
          ],
        "uservoice:uservoice/article" => [
            "[Uservoice] New article: Is this a new article?",
            "[Uservoice] http://test.uservoice.com/knowledgebase/articles/-is-this-a-new-article-"
          ],
        "uservoice:uservoice/forum" => [
            "[Uservoice] New forum: Test forum",
            "[Uservoice] http://test.uservoice.com/forums/-test-forum"
          ],
        "uservoice:uservoice/kudo" => [
            "[Uservoice] Test Message Sender received Kudos! from Test Kudo Sender on Test subject",
            "[Uservoice] http://test.uservoice.com/admin/tickets/1"
          ],
        "uservoice:uservoice/suggestion_status_changed" => [
            "[Uservoice] Test suggestion: completed",
            "[Uservoice] http://test.uservoice.com/forums/739109572-test-forum/suggestions/-test-suggestion"
          ],
        "uservoice:uservoice/ticket" => [
            "[Uservoice] New ticket: Test subject",
            "[Uservoice] http://test.uservoice.com/admin/tickets/1"
          ],
        "uservoice:uservoice/ticket_reply" => [
            "[Uservoice] New reply on: Test subject",
            "[Uservoice] http://test.uservoice.com/admin/tickets/1"
          ],
        "pivotaltracker:pivotaltracker/story_create" => [
            "[Pivotal Tracker] Otto Hilska added \"The greatest story ever\"",
            "[Pivotal Tracker] https://www.pivotaltracker.com/story/show/7877517"
          ],
        "pivotaltracker:pivotaltracker/multi_story_edit" => [
            "[Pivotal Tracker] Otto Hilska edited 3 stories",
            "[Pivotal Tracker] https://www.pivotaltracker.com/story/show/6363057",
            "[Pivotal Tracker] https://www.pivotaltracker.com/story/show/6363061",
            "[Pivotal Tracker] https://www.pivotaltracker.com/story/show/7877517"
          ],
        "twitter" => [
            "[Twitter] FlowdockRumors: /server -ssl http://t.co/wGqvQmbP 6697"
          ],
        "twitter:multiline_tweet" => [
            "[Twitter] FlowdockRumors: /server -ssl http://t.co/wGqvQmbP 6697",
            "KICK Otto"
          ],
        "zendesk" => [
            "[Zendesk] Arttu Tervo commented ticket",
            "[Zendesk] http://testcompany.zendesk.com/tickets/2"
          ],
        "activity" => [
            "[Oulu Test app (Source name): Test thread] Oskari Virtanen: Test message with link"
          ],
        "discussion" => [
            "[Oulu Test app (Source name): Test thread] Oskari Virtanen: commented on ticket"
        ]
      }.each_pair do |_event, content|
        event, fixture = (_event.match(':') && _event.split(':') || [_event, _event])

        it "should render #{_event} event" do
          prefix = ":#{IrcServer::FLOWDOCK_USER} NOTICE #{@channel.irc_id} :"
          event = FlowdockEvent.from_message(@irc_connection, message_hash("#{fixture}_event"))
          expect(event).to be_valid
          expect(event.render).to eq("#{prefix}#{content.join("\r\n#{prefix}")}")
        end

        it "should not be valid as private events" do
          event = FlowdockEvent.from_message(@irc_connection, message_hash("#{fixture}_event"))
          allow(event).to receive(:channel?).and_return(false)
          expect(event).not_to be_valid
        end
      end
    end
  end

  describe "presence" do
    before(:each) do
      expect(@irc_connection).to receive(:find_user_by_id).once do |arg|
        @channel.find_user_by_id(arg)
      end
    end

    it "should update user's state" do
      message_event = message_hash('presence_event')
      expect(@irc_connection).to receive(:channels).and_return({ @channel.id => @channel })
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      event.process
      user = @channel.find_user_by_id(1)
      expect(user.presence).to eq(:active)
      expect(user.last_presence_update.to_s).to eq("2015-05-27 13:09:38 UTC")
    end
  end

  describe "adding and removing flows" do
    it "should part channel when blocked" do
      remove_event = message_hash('flow_remove_event')
      expect(@irc_connection).to receive(:user_id).and_return(1)
      expect(@irc_connection).to receive(:find_user_by_id).once { |arg| @channel.find_user_by_id(arg) }
      expect(@irc_connection).to receive(:find_channel_by_id).with("irc:ottotest").and_return(@channel)

      expect(@irc_connection).to receive(:remove_channel).with(@channel)
      expect(@irc_connection).to receive(:send_reply).with(':Otto!otto@example.com PART #irc/ottotest')

      event = FlowdockEvent.from_message(@irc_connection, remove_event)
      expect(event).to be_valid
      event.process
    end

    it "should join channel when added to new flow" do
      add_event = message_hash('flow_add_event')
      expect(@irc_connection).to receive(:user_id).and_return(1)
      expect(@irc_connection).to receive(:find_user_by_id).once { |arg| @channel.find_user_by_id(arg) }
      expect(@irc_connection).to receive(:add_channel).with(add_event['content'])

      event = FlowdockEvent.from_message(@irc_connection, add_event)
      expect(event).to be_valid
      event.process
    end
  end

  describe "private message parsing" do
    before(:each) do
      target_user = @channel.find_user_by_id("50000")
      sender = @channel.find_user_by_id("1")
      expect(@irc_connection).to receive(:find_user_by_id).with("50000").once.and_return(target_user)
      expect(@irc_connection).to receive(:find_user_by_id).with("1").once.and_return(sender)
    end

    it "should process private chat message" do
      message_event = message_hash('private_message')
      expect(@irc_connection).to receive(:user_id).and_return(50000)
      expect(@irc_connection).to receive(:remove_outgoing_message).with(message_event).and_return(false)

      expect(@irc_connection).to receive(:send_reply).with(":Otto!otto@example.com PRIVMSG Ottomob :<907> private test").once
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      event.process
    end

    it "should render private chat message" do
      message_event = message_hash('private_message')

      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      expect(event.render).to eq(":Otto!otto@example.com PRIVMSG Ottomob :<907> private test")
    end

    it "should not render private chat messages sent by the user itself in other session" do
      message_event = message_hash('private_message')
      expect(@irc_connection).to receive(:user_id).and_return(1)
      expect(@irc_connection).not_to receive(:send_reply)

      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      event.process
    end

    it "should render private file upload event" do
      message_event = message_hash('file_event_private')
      event = FlowdockEvent.from_message(@irc_connection, message_event)
      expect(event).to be_valid
      expect(event.render).to eq(":Otto!otto@example.com PRIVMSG Ottomob :https://www.#{IrcServer::FLOWDOCK_DOMAIN}/rest/private/1/2/files/Sse2n5VKLlLeafMsjFLuxA/globe.rb")
    end
  end

  describe "message editing" do
    before :each do
      expect(@irc_connection).to receive(:email).and_return("test@email.com")
      expect(@irc_connection).to receive(:password).and_return("abcd1234")

      expect(@irc_connection).to receive(:find_channel_by_id).with("irc:ottotest").and_return(@channel)
      sender = @channel.find_user_by_id("1")
      expect(@irc_connection).to receive(:find_user_by_id).with("1").once.and_return(sender)
    end

    it "should process message edit event for message" do
      stub_request(:get, "https://api.flowdock.com/flows/irc/ottotest/messages/374").
        to_return(status: 200, body: response_stub("message_event"))

      expect(@irc_connection).to receive(:send_reply).with(":Otto!otto@example.com PRIVMSG #irc/ottotest :updated test message*")

      EventMachine.run {
        message_event = message_hash("message_edit_event_for_message")
        event = FlowdockEvent.from_message(@irc_connection, message_event)
        expect(event).to be_valid
        event.process

        EventMachine.stop
      }
    end

    it "should process message edit event for comment" do
      stub_request(:get, "https://api.flowdock.com/flows/irc/ottotest/messages/1904").
        to_return(status: 200, body: response_stub("comment_event"))

      expect(@irc_connection).to receive(:send_reply).with(":Otto!otto@example.com PRIVMSG #irc/ottotest :[test] << test comment edited*")

      EventMachine.run {
        message_event = message_hash("message_edit_event_for_comment")
        event = FlowdockEvent.from_message(@irc_connection, message_event)
        expect(event).to be_valid
        event.process

        EventMachine.stop
      }
    end

    it "should not process message edit event for too old message" do
      stub_request(:get, "https://api.flowdock.com/flows/irc/ottotest/messages/374").
        to_return(status: 200, body: response_stub("message_event", Time.now - 120))

      expect(@irc_connection).not_to receive(:send_reply)

      EventMachine.run {
        message_event = message_hash("message_edit_event_for_message")
        event = FlowdockEvent.from_message(@irc_connection, message_event)
        expect(event).to be_valid
        event.process

        EventMachine.stop
      }
    end

    def response_stub(fixture, sent = Time.now)
      response = message_hash(fixture).merge({ 'sent' => sent.to_i * 1000})
      MultiJson.dump(response)
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
