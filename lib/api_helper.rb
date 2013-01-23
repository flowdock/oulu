class ApiHelper
  def initialize(email, password)
    @email = email
    @password = password
  end

  def get(resource, additional_headers = nil)
    do_request(:get, resource, additional_headers)
  end

  def post(resource, additional_headers = nil, body = nil)
    do_request(:post, resource, additional_headers, body)
  end

  private

  def do_request(type, resource, additional_headers = nil, body = nil)
    http = EventMachine::HttpRequest.new(api_url(resource))
    headers = if additional_headers
      authorization.merge(additional_headers)
    else
      authorization
    end

    case type
    when :get then http.get(head: headers)
    when :post then http.post(head: headers, body: body)
    end
  end

  def api_url(resource)
    "https://api.#{IrcServer::FLOWDOCK_DOMAIN}/v1/#{resource}"
  end

  def authorization
    { 'authorization' => [@email, @password] }
  end
end
