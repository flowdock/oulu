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
