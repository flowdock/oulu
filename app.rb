require 'rubygems'
require 'bundler'
require File.expand_path('../environment', __FILE__)

IRC_PORT = ENV['PORT'].to_i
raise "Please specify PORT environment variable." unless IRC_PORT > 0

STDOUT.sync = true

EventMachine.run {
  EventMachine.start_server '0.0.0.0', IRC_PORT, IrcConnection
  $logger.info "Running IRC server on #{IRC_PORT}"
}
