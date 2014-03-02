# encoding: utf-8
require 'spec_helper'

describe EmojiCleaner do
  it "Converts emoji characters to their string alias" do
    described_class.perform("test 😡 ").should eq "test :rage: "
  end
end
