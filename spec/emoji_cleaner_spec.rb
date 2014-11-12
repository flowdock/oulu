# encoding: utf-8
require 'spec_helper'

describe EmojiCleaner do
  it "Converts emoji characters to their string alias" do
    expect(described_class.perform("test 😡 ")).to eq "test :rage: "
  end

  it "Ignores non-string arguments" do
    expect(described_class.perform( "holla" => "oi" )).to eq  "holla" => "oi"
  end
end
