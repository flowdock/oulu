# encoding: utf-8
require 'spec_helper'

describe IrcParser do
  class FoobarCommand; end

  before(:each) do
    IrcParser.register_command :FOOBAR, FoobarCommand
  end

  it "should work with optional userhost in the beginning" do
    klass, args = IrcParser.parse(":Mutru!otto.hilska@example.com FOOBAR :leet")
    expect(klass).to eq(FoobarCommand)
    expect(args).to eq(["leet"])
  end

  it "should work without optional userhost" do
    klass, args = IrcParser.parse("FOOBAR :leet")
    expect(klass).to eq(FoobarCommand)
    expect(args).to eq(["leet"])
  end

  it "should handle long :prefixed arguments" do
    klass, args = IrcParser.parse("FOOBAR :long value")
    expect(klass).to eq(FoobarCommand)
    expect(args).to eq(["long value"])
  end

  it "should parse messages with more arguments, last of them :prefixed" do
    klass, args = IrcParser.parse("FOOBAR first second :long value wtf!")
    expect(klass).to eq(FoobarCommand)
    expect(args).to eq(["first", "second", "long value wtf!"])
  end

  it "should understand colons within the :prefixed argument" do
    klass, args = IrcParser.parse("FOOBAR #funny/argument :Cool :)")
    expect(klass).to eq(FoobarCommand)
    expect(args).to eq(["#funny/argument", "Cool :)"])
  end

  it "should understand lots of arguments and colons everywhere" do
    klass, args = IrcParser.parse("FOOBAR first #second/channel ::What :) Ok :) !!!!:")
    expect(klass).to eq(FoobarCommand)
    expect(args).to eq(["first", "#second/channel", ":What :) Ok :) !!!!:"])
  end

  it "should understand lowercase commands" do
    klass, args = IrcParser.parse("motd")
    expect(klass).to eq(MotdCommand)
    expect(args).to be_empty
  end

  it "should return UTF-8" do
    command = "WHOIS test".force_encoding(Encoding::ASCII_8BIT)
    klass, args = IrcParser.parse(command)
    expect(klass).to eq(WhoisCommand)
    expect(args.first.encoding).to eq(Encoding::UTF_8)
  end

  it "should encode LATIN1 to UTF-8" do
    command = 'WHOIS tår'.encode(Encoding::ISO8859_1).force_encoding(Encoding::ASCII_8BIT)
    klass, args = IrcParser.parse(command)
    expect(klass).to eq(WhoisCommand)
    expect(args.first.encoding).to eq(Encoding::UTF_8)
    expect(args.first).to eq('tår')
  end

  it "should survive empty messages" do
    klass, args = IrcParser.parse("")
    expect(klass).to eq(nil)
    expect(args).to eq([])
  end

  it "should survive nil values" do
    klass, args = IrcParser.parse(nil)
    expect(klass).to eq(nil)
    expect(args).to eq([])
  end
end
