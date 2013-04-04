require File.expand_path('../../environment', __FILE__)

$test_stdout = StringIO.new
$logger = Logger.new($test_stdout)

require 'rspec'
require 'webmock/rspec'

RSpec.configure do |config|
end

def fixture(file)
  File.read(File.join("spec", "fixtures", "#{file}.json"))
end

def example_irc_channel(irc_connection, number=0)
  IrcChannel.new(irc_connection, Yajl::Parser.parse(fixture('flows'))[number])
end

# Silently change a constant
def reset_constant(klass, constant, new_value)
  klass.send(:remove_const, constant)
  klass.const_set(constant, new_value)
end
