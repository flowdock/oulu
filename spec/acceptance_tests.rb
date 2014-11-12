# Check out README for instructions.
#
require File.expand_path('../../environment', __FILE__)

require 'rspec'
require 'net/https'
require 'uri'
require 'cinch'

RSpec.configure do |config|
end

IRC_PORT = 6670
IRC_HOST = '127.0.0.1'

TEST_USER = ENV['TEST_USER']
TEST_PASSWORD = ENV['TEST_PASSWORD']
TEST_FLOW = ENV['TEST_FLOW']
FLOWDOCK_DOMAIN = ENV['FLOWDOCK_DOMAIN'] || "flowdock.com"
TEST_RUN_TIMESTAMP = Time.now.to_i
TEST_RUN_TIMEOUT = 5 # minutes

def post_to_chat(message)
  json = Yajl::Encoder.encode({ :event => 'message', :content => message, :tags => [] })
  do_post("https://api.#{FLOWDOCK_DOMAIN}/flows/#{TEST_FLOW}/messages", json)
end

def post_to_influx(subject, message)
  json = Yajl::Encoder.encode({ :event => 'mail', :subject => subject, :content => message, :tags => [],
    :source => "acceptance-test", :from_address => TEST_USER })
  do_post("https://api.#{FLOWDOCK_DOMAIN}/flows/#{TEST_FLOW}/messages", json)
end

def do_post(url, json)
  uri = URI(url)
  req = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
  req.body = json
  req.basic_auth(TEST_USER, TEST_PASSWORD)
  puts "\nPosting to API: #{url}\n"
  Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https'), :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
    res = http.request(req)
    raise RuntimeError.new("Failed to post to API (#{res.code}): #{res.body}") unless res.code.to_i == 201
  end
end

# Only run when the environment is configured.
describe "Acceptance Tests" do
  def start_server
    @server = Thread.new do
      EventMachine.run {
        EventMachine.start_server '127.0.0.1', IRC_PORT, IrcConnection
      }
    end
  end

  it "should authenticate successfully" do
    start_server

    bot = Cinch::Bot.new do
      configure do |c|
        c.server = IRC_HOST
        c.port = IRC_PORT
        c.channels = []
      end

      on :notice, /identify via/ do |m, text|
        m.user.send "identify #{TEST_USER} #{TEST_PASSWORD}"
      end

      on :join do |m|
        if m.channel.name == "#" + TEST_FLOW
          # Ensure channel is fully synced
          EventMachine.add_timer 2 do
            m.channel.send "Hello world!"
            post_to_chat("Posted from API at #{TEST_RUN_TIMESTAMP}")
          end
        end
      end

      on :message, /Posted from API at (\d+)/ do |m, at|
        if at.to_i == TEST_RUN_TIMESTAMP
          post_to_influx("Great email", "Posted from API at #{TEST_RUN_TIMESTAMP}")
        end
      end

      on :notice, /\[Email\] #{Regexp.escape(TEST_USER)}: Great email/ do |m, at|
        bot.quit
      end
    end

    bot.loggers.level = if ENV['LOG_LEVEL']
      ENV['LOG_LEVEL'].to_sym
    else
      :log
    end

    begin
      Timeout::timeout(TEST_RUN_TIMEOUT * 60) { # minutes
        bot.start

        EventMachine.stop
      }
    rescue Timeout::Error
      raise RuntimeError.new("Irc bot failed to complete acceptance tests in #{TEST_RUN_TIMEOUT} minutes")
    end
  end
end if TEST_USER && TEST_PASSWORD && TEST_FLOW
