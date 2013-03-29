require 'spec_helper'

describe IrcParser do
  class FoobarCommand; end

  before(:each) do
    IrcParser.register_command :FOOBAR, FoobarCommand
  end

  it "should work with optional userhost in the beginning" do
    klass, args = IrcParser.parse(":Mutru!otto.hilska@example.com FOOBAR :leet")
    klass.should == FoobarCommand
    args.should == ["leet"]
  end

  it "should work without optional userhost" do
    klass, args = IrcParser.parse("FOOBAR :leet")
    klass.should == FoobarCommand
    args.should == ["leet"]
  end

  it "should handle long :prefixed arguments" do
    klass, args = IrcParser.parse("FOOBAR :long value")
    klass.should == FoobarCommand
    args.should == ["long value"]
  end

  it "should parse messages with more arguments, last of them :prefixed" do
    klass, args = IrcParser.parse("FOOBAR first second :long value wtf!")
    klass.should == FoobarCommand
    args.should == ["first", "second", "long value wtf!"]
  end

  it "should understand colons within the :prefixed argument" do
    klass, args = IrcParser.parse("FOOBAR #funny/argument :Cool :)")
    klass.should == FoobarCommand
    args.should == ["#funny/argument", "Cool :)"]
  end

  it "should understand lots of arguments and colons everywhere" do
    klass, args = IrcParser.parse("FOOBAR first #second/channel ::What :) Ok :) !!!!:")
    klass.should == FoobarCommand
    args.should == ["first", "#second/channel", ":What :) Ok :) !!!!:"]
  end

  it "should understand lowercase commands" do
    klass, args = IrcParser.parse("motd")
    klass.should == MotdCommand
    args.should be_empty
  end

  it "should survive empty messages" do
    klass, args = IrcParser.parse("")
    klass.should == nil
    args.should == []
  end

  it "should survive nil values" do
    klass, args = IrcParser.parse(nil)
    klass.should == nil
    args.should == []
  end
end
