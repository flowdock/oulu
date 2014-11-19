source "https://rubygems.org"

gem 'em-http-request', :github => 'igrigorik/em-http-request', :ref => '1f298bfc7eafae7ab3ebcb5b5a890d19a62e8d4b'
gem 'em-eventsource'
gem 'multi_json'
gem 'yajl-ruby', :require => ['yajl', 'yajl/json_gem']
gem 'gemoji', :github => 'github/gemoji', :ref => "204ace76dac5ea54ab79a7395640d29b3dd8b0fb"

gem 'html-pipeline'

group :development do
  gem 'foreman'

  gem 'pry'
  gem 'pry-byebug', platforms: :ruby_20
  gem 'pry-debugger', platforms: :ruby_19
  gem 'pry-stack_explorer'
end

group :test do
  gem 'rspec'
  gem 'webmock'
  # For acceptance tests
  gem 'cinch', '~> 2'
end
