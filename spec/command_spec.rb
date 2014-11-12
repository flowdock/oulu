require 'spec_helper'

describe Command do
  before(:each) do
    @irc_connection = double(:irc_connection, :nick => 'Mutru',
      :email => 'otto.hilska@example.com', :real_name => 'Otto Hilska')
  end

  describe "command who doesn't override necessary methods" do
    class LackingCommand < Command
    end

    it "should raise error when calling set_data" do
      cmd = LackingCommand.new(@irc_connection)
      expect { cmd.set_data([]) }.to raise_error(NotImplementedError)
    end

    it "should raise error when calling execute!" do
      cmd = LackingCommand.new(@irc_connection)
      expect { cmd.execute! }.to raise_error(NotImplementedError)
    end

    it "should raise error when calling valid?" do
      cmd = LackingCommand.new(@irc_connection)
      expect { cmd.valid? }.to raise_error(NotImplementedError)
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
    expect(klass).to eq(GoodCommand)
    expect(args).to eq(["Robin"])
  end

  it "should know how to validate itself when data is set" do
    cmd = GoodCommand.new(@irc_connection)
    cmd.set_data(["Robin"])
    expect(cmd).to be_valid

    cmd2 = GoodCommand.new(@irc_connection)
    cmd2.set_data([])
    expect(cmd2).not_to be_valid
  end

  it "should have references to user info" do
    cmd = GoodCommand.new(@irc_connection)
    expect(cmd.send(:user_nick)).to eq(@irc_connection.nick)
    expect(cmd.send(:user_email)).to eq(@irc_connection.email)
    expect(cmd.send(:user_real_name)).to eq(@irc_connection.real_name)
  end

  it "should delegate channel finding to IrcConnection" do
    channel = double(:channel)
    expect(@irc_connection).to receive(:find_channel_by_name).and_return(channel)

    cmd = GoodCommand.new(@irc_connection)
    expect(cmd.send(:find_channel, "#test/main")).to eq(channel)
  end

  it "should send reply text to IrcConnection" do
    expect(@irc_connection).to receive(:send_reply).with("Flowdock is great")
    cmd = GoodCommand.new(@irc_connection)
    cmd.set_data(["Flowdock"])
    expect(cmd).to be_valid
    cmd.execute!
  end

  it "should know how to send multiple lines of replies" do
    expect(@irc_connection).to receive(:send_reply).with("Flowdock\r\nis\r\ngreat")
    cmd = GoodCommand.new(@irc_connection)
    cmd.send(:send_replies, ["Flowdock", "is", "great"])
  end
end
