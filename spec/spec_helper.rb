require File.expand_path('../../environment', __FILE__)

require 'rspec'
require 'webmock/rspec'

RSpec.configure do |config|
end

def fixture(file)
  File.read(File.join("spec", "fixtures", "#{file}.json"))
end

def example_irc_channel(irc_connection)
  IrcChannel.new(irc_connection, Yajl::Parser.parse(fixture('flows')).first)
end
