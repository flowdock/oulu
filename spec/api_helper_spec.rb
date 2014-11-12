require 'spec_helper'

describe ApiHelper do
  before :each do
    @email = "testguy@testemail.com"
    @password = "abcd1234"

    @api_helper = ApiHelper.new(@email, @password)
  end

  describe "Initialization" do
    it "should throw an error if trying to initialize with nil arguments" do
      expect{ApiHelper.new(nil, "password")}.to raise_error(ArgumentError)
      expect{ApiHelper.new("email", nil)}.to raise_error(ArgumentError)
      expect{ApiHelper.new(nil, nil)}.to raise_error(ArgumentError)
    end
  end

  describe "GET request" do
    it "should do GET request with authentication token" do
      stub_request(:get, "https://api.flowdock.com/resource").
        with(:headers => {'Authorization'=>[@email, @password]}).
        to_return(:status => 200)

      EventMachine.run {
        http = @api_helper.get(ApiHelper.api_url("resource"))
        verify_and_stop(http)
      }
    end

    it "should do GET request with additional headers" do
      stub_request(:get, "https://api.flowdock.com/resource").
        with(:headers => {'Authorization'=>[@email, @password], 'Content-Type' => 'application/json'}).
        to_return(:status => 200)

      EventMachine.run {
        http = @api_helper.get(ApiHelper.api_url("resource"), {'Content-Type' => 'application/json'})
        verify_and_stop(http)
      }
    end
  end

  describe "POST request" do
    it "should do POST request with authentication token" do
      stub_request(:post, "https://api.flowdock.com/resource").
        with(:headers => {'Authorization'=>[@email, @password]}).
        to_return(:status => 200)

      EventMachine.run {
        http = @api_helper.post(ApiHelper.api_url("resource"))
        verify_and_stop(http)
      }
    end

    it "should do POST with additional headers" do
      stub_request(:post, "https://api.flowdock.com/resource").
        with(:headers => {'Authorization'=>[@email, @password], 'Content-Type' => 'application/json'}).
        to_return(:status => 200)

      EventMachine.run {
        http = @api_helper.post(ApiHelper.api_url("resource"), { 'Content-Type' => 'application/json'})
        verify_and_stop(http)
      }
    end

    it 'should do POST with a body' do
      post_body = '{"post": "body"}'
      stub_request(:post, "https://api.flowdock.com/resource").
        with(:body => post_body,
            :headers => {'Authorization'=>[@email, @password], 'Content-Type'=>'application/json'}).
        to_return(:status => 200)

      EventMachine.run {
        http = @api_helper.post(ApiHelper.api_url("resource"), { 'Content-Type' => 'application/json'}, post_body)
        verify_and_stop(http)
      }
    end
  end

  def verify_and_stop(http)
    http.callback do
      expect(http.response_header.status).to eq(200)
      EventMachine.stop
    end

    http.errback { EventMachine.stop }
  end
end
