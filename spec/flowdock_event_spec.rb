require 'spec_helper'

describe FlowdockEvent do
  before(:each) do
    @irc_connection = mock(:irc_connection)
    flow_hash = Yajl::Parser.parse(fixture('flows')).first

    @channel = IrcChannel.new(@irc_connection, flow_hash)
  end

  describe "with parsing events" do
    before(:each) do
      @irc_connection.should_receive(:find_channel).with("irc:ottotest").and_return(@channel)
    end

    it "should handle join event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('join_event'))
      event.valid?.should == true
    end

    it "should handle block event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('block_event'))
      event.valid?.should == true
    end

    it "should handle add_people event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('add_people_event'))
      event.valid?.should == true
    end

    it "should handle comment event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('comment_event'))
      event.valid?.should == true
    end

    it "should handle line event (/me in desktop Flowdock)" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('line_event'))
      event.valid?.should == true
    end

    it "should handle status event" do
      event = FlowdockEvent.from_message(@irc_connection, message_hash('status_event'))
      event.valid?.should == true
    end
  end

  def message_hash(event)
    Yajl::Parser.parse(fixture("flowdock_events/#{event}"))
  end
end
