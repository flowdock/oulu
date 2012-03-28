# Oulu: The Flowdock IRC Gateway

This component acts as an IRC server, and bridges the messages between clients and Flowdock.

## Running tests

Use: `bundle exec rspec`

# Running acceptance tests

Use: `TEST_USER="foo@bar.fi" TEST_PASSWORD="..." TEST_FLOW="mytest/main" bundle exec rspec spec/acceptance_tests.rb`

## Running the server

Use: `foreman start`

Possible environment configuration:

* *PORT* - IRC server port (optional, default value: chosen by foreman)
* *FLOWDOCK_DOMAIN* - where's your Flowdock at? (optional, default value: flowdock.com)

## Deploying to Flowdock's server environments

There's a separate repository with deployment scripts and instructions.
