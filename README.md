# Oulu: The Flowdock IRC Gateway [![Build Status](https://travis-ci.org/flowdock/oulu.png?branch=master)](https://travis-ci.org/flowdock/oulu)

This component acts as an IRC server, and bridges the messages between clients and Flowdock.

## Prerequisites

Oulu uses bundler, so simply run `bundle install` before running tests. No
database is needed.

## Running tests

Use: `bundle exec rspec`

# Running acceptance tests

Use: `TEST_USER="foo@bar.fi" TEST_PASSWORD="..." TEST_FLOW="mytest/main" bundle exec rspec spec/acceptance_tests.rb`

## Running the server

Use: `foreman start`

Possible environment configuration:

* *FLOWDOCK_DOMAIN* - where's your Flowdock at? (optional, default value: flowdock.com)

Define port using command line parameter `--port` (optional, defaults to foreman's default port)

## Deploying to Flowdock's server environments

There's a separate repository with deployment scripts and instructions.
