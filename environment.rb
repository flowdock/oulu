$:.unshift File.expand_path("../lib", __FILE__)
Bundler.require(:default)

require 'logger'

$logger = Logger.new(STDOUT)
$logger.level = Logger.const_get(ENV['LOG_LEVEL']) rescue Logger::INFO

require 'user'
require 'irc_parser'
require 'command_views'
require 'flowdock_connection'
require 'flowdock_event'
require 'irc_server'
require 'irc_connection'
require 'irc_channel'
require 'authentication_helper'
require 'command'
require 'api_helper'
