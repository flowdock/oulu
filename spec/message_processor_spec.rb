# encoding: utf-8
require 'spec_helper'

describe MessageProcessor do
  let :processor do
    described_class.new message
  end

  let :message do
    {
      "content" =>  { "text" => "test" }
    }
  end

  it "cleans up message content if needed" do
    expect(processor.perform).to eq(message)
  end

  context "With emoji" do
    let :message do
      {
        "content" => {
          "uuid" => "something",
          "text" => "foo 😡",
          "title" => "some title"
        }
      }
    end

    let :expected do
      {
        "content" => {
          "uuid" => "something",
          "text" => "foo :rage:",
          "title" => "some title"
        }
      }
    end

    it "Cleans up emoji from message content" do
      expect(processor.perform).to eq(expected)
    end
  end
end
