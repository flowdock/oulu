[![Stories in Ready](https://badge.waffle.io/flowdock/oulu.png)](http://waffle.io/flowdock/oulu)
# Oulu: The Flowdock IRC Gateway [![Build Status](https://travis-ci.org/flowdock/oulu.png?branch=master)](https://travis-ci.org/flowdock/oulu)

This component acts as an IRC server, and bridges the messages between clients and Flowdock.

If you're looking to simply use this IRC gateway, check out the [help page](https://www.flowdock.com/help/irc).

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
* *FLOWDOCK_UNSECURE_HTTP* - use http instead of https. This makes
  testing on your local machine much nicer.

There is a `sample.env` file which should suffice for local testing so you can just

    ln -s sample.env .env

Define port using command line parameter `--port` (optional, defaults to foreman's default port)

## Deploying to Flowdock's server environments

There's a separate repository with deployment scripts and instructions.

## Docker

    $ docker-compose up -d --build
    $ docker attach $(docker-compose ps -q irssi)