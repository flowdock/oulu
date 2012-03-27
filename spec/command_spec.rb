require 'spec_helper'

describe Command do
  before(:each) do
    @irc_connection = mock(:irc_connection, :nick => 'Mutru',
      :email => 'otto.hilska@example.com', :real_name => 'Otto Hilska')
  end

  describe "command who doesn't override necessary methods" do
    class LackingCommand < Command
    end

    it "should raise error when calling set_data" do
      cmd = LackingCommand.new(@irc_connection)
      lambda {
        cmd.set_data([])
      }.should raise_error(NotImplementedError)
    end

    it "should raise error when calling execute!" do
      cmd = LackingCommand.new(@irc_connection)
      lambda {
        cmd.execute!
      }.should raise_error(NotImplementedError)
    end

    it "should raise error when calling valid?" do
      cmd = LackingCommand.new(@irc_connection)
      lambda {
        cmd.valid?
      }.should raise_error(NotImplementedError)
    end
  end

  class GoodCommand < Command
    register_command :GOOD

    def set_data(args)
      @name = args.first
    end

    def valid?
      !!@name
    end

    def execute!
      send_reply "#{@name} is great"
    end
  end

  it "should have registered the command to IrcParser" do
    klass, args = IrcParser.parse("GOOD :Robin")
    klass.should == GoodCommand
    args.should == ["Robin"]
  end

  it "should know how to validate itself when data is set" do
    cmd = GoodCommand.new(@irc_connection)
    cmd.set_data(["Robin"])
    cmd.valid?.should == true

    cmd2 = GoodCommand.new(@irc_connection)
    cmd2.set_data([])
    cmd2.valid?.should == false
  end

  it "should have references to user info" do
    cmd = GoodCommand.new(@irc_connection)
    cmd.send(:user_nick).should == @irc_connection.nick
    cmd.send(:user_email).should == @irc_connection.email
    cmd.send(:user_real_name).should == @irc_connection.real_name
  end

  it "should delegate channel finding to IrcConnection" do
    channel = mock(:channel)
    @irc_connection.should_receive(:find_channel).and_return(channel)

    cmd = GoodCommand.new(@irc_connection)
    cmd.send(:find_channel, "#test/main").should == channel
  end

  it "should send reply text to IrcConnection" do
    @irc_connection.should_receive(:send_reply).with("Flowdock is great")
    cmd = GoodCommand.new(@irc_connection)
    cmd.set_data(["Flowdock"])
    cmd.valid?.should == true
    cmd.execute!
  end

  it "should know how to send multiple lines of replies" do
    @irc_connection.should_receive(:send_reply).with("Flowdock\r\nis\r\ngreat")
    cmd = GoodCommand.new(@irc_connection)
    cmd.send(:send_replies, ["Flowdock", "is", "great"])
  end
end
