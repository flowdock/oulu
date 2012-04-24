# Check out README for instructions.
#
require File.expand_path('../../environment', __FILE__)

require 'rspec'
require 'net/https'
require 'uri'

RSpec.configure do |config|
end

IRC_PORT = 6670
IRC_HOST = '127.0.0.1'

TEST_USER = ENV['TEST_USER']
TEST_PASSWORD = ENV['TEST_PASSWORD']
TEST_FLOW = ENV['TEST_FLOW']
TEST_RUN_TIMESTAMP = Time.now.to_i

def post_to_chat(message)
  json = Yajl::Encoder.encode({ :event => 'message', :content => message, :tags => [] })
  do_post("https://api.flowdock.com/flows/#{TEST_FLOW}/messages", json)
end

def post_to_influx(subject, message)
  json = Yajl::Encoder.encode({ :event => 'mail', :subject => subject, :content => message, :tags => [],
    :source => "acceptance-test", :from_address => "fdbamboo@testmail.mutru.fi" })
  do_post("https://api.flowdock.com/flows/#{TEST_FLOW}/messages", json)
end

def do_post(url, json)
  uri = URI(url)
  req = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
  req.body = json
  req.basic_auth(TEST_USER, TEST_PASSWORD)

  Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https'), :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
    res = http.request(req)
    raise RuntimeError.new("Failed to post to API") unless res.code.to_i == 200
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
        c.verbose = true
      end

      on :notice, /identify via/ do |m, text|
        m.user.send "identify #{TEST_USER} #{TEST_PASSWORD}"
      end

      on :join do |m|
        if m.channel.name == "#" + TEST_FLOW
          m.channel.send "Hello world!"
          post_to_chat("Posted from API at #{TEST_RUN_TIMESTAMP}")
        end
      end

      on :message, /Posted from API at (\d+)/ do |m, at|
        at.to_i.should == TEST_RUN_TIMESTAMP
        post_to_influx("Great email", "Posted from API at #{TEST_RUN_TIMESTAMP}")
      end

      on :notice, /\[Email\] Great email/ do |m, at|
        bot.quit
      end
    end

    bot.start

    EventMachine.stop
  end
end if TEST_USER && TEST_PASSWORD && TEST_FLOW
