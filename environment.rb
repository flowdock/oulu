$:.unshift File.expand_path("../lib", __FILE__)
Bundler.require(:default)

require 'user'
require 'irc_parser'
require 'flowdock_connection'
require 'irc_server'
require 'irc_connection'
require 'irc_channel'
require 'command_views'
require 'command'
