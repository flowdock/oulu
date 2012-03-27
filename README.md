# Oulu: The Flowdock IRC Gateway

This component acts as an IRC server, and bridges the messages between clients and Flowdock.

## Running tests

Use: `bundle exec rspec`

# Running acceptance tests

Use: `TEST_USER="foo@bar.fi" TEST_PASSWORD="..." TEST_FLOW="mytest/main" bundle exec rspec spec/acceptance_tests.rb`

## Running the server

Use: `foreman start`
