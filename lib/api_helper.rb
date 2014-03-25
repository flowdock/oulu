class ApiHelper
  def initialize(email, password)
    raise ArgumentError.new "Undefined email or password" if email.nil? || password.nil?
    @email = email
    @password = password
  end

  def get(resource, additional_headers = nil)
    do_request(:get, resource, additional_headers)
  end

  def put(resource, additional_headers = nil, body = nil)
    do_request(:put, resource, additional_headers, body)
  end

  def post(resource, additional_headers = nil, body = nil)
    do_request(:post, resource, additional_headers, body)
  end

  private

  def do_request(type, resource, additional_headers = nil, body = nil)
    http = EventMachine::HttpRequest.new(resource, :connect_timeout => 20, :inactivity_timeout => 20)
    headers = if additional_headers
      authorization.merge(additional_headers)
    else
      authorization
    end

    case type
    when :get then http.get(head: headers)
    when :put then http.put(head: headers, body: body)
    when :post then http.post(head: headers, body: body)
    end
  end

  def self.api_url(resource)
    (ENV["FLOWDOCK_UNSECURE_HTTP"] ? "http" : "https") + "://api.#{IrcServer::FLOWDOCK_DOMAIN}/#{resource}"
  end

  def authorization
    { 'authorization' => [@email, @password] }
  end
end
