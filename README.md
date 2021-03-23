# SquareEvent

<!-- [![Build Status](https://secure.travis-ci.org/jammed-org/square_event.svg)](http://travis-ci.org/integrallis/stripe_event)
[![Gem Version](https://badge.fury.io/rb/stripe_event.svg)](http://badge.fury.io/rb/stripe_event)
[![Code Climate](https://codeclimate.com/github/integrallis/stripe_event.svg)](https://codeclimate.com/github/integrallis/stripe_event)
[![Coverage Status](https://coveralls.io/repos/integrallis/stripe_event/badge.svg)](https://coveralls.io/r/integrallis/stripe_event)
[![Gem Downloads](https://img.shields.io/gem/dt/stripe_event.svg)](https://rubygems.org/gems/stripe_event) -->

SquareEvent is built on the [ActiveSupport::Notifications API](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html). Incoming webhook requests are [authenticated with the webhook signature](#authenticating-webhooks-with-signatures). Define subscribers to handle specific event types. Subscribers can be a block or an object that responds to `#call`.

The gem is based on the excellent [Stripe Event](https://github.com/integrallis/stripe_event) work from Integrallis Software, it has been adapted and re-written to work with Square webhooks.

## Install

```ruby
# Gemfile
gem 'square_event'
```

```ruby
# config/routes.rb
mount SquareEvent::Engine, at: '/my-chosen-path' # provide a custom path
```

## Usage

```ruby
# config/initializers/stripe.rb
SquareEvent.signing_secret   = Rails.application.credentials.square[Rails.env][:webhook_secret]
SquareEvent.notification_url = Rails.application.credentials.square[Rails.env][:webhook_url]

SquareEvent.configure do |events|
  events.subscribe 'payment.created' do |event|
    # Define subscriber behavior based on the event object
    event.class       #=> SquareEvent::Event
    event.type        #=> "payment.created"
    event.data        #=> data": { "type": "payment", "id": "KkAkhdMs...
  end

  events.all do |event|
    # Handle all event types - logging, etc.
  end
end
```

### Subscriber or interactor objects that respond to #call

```ruby
class CustomerCreated
  def call(event)
    # Event handling
  end
end

class BillingEventLogger
  def initialize(logger)
    @logger = logger
  end

  def call(event)
    @logger.info "BILLING:#{event.type}:#{event.id}"
  end
end
```

```ruby
SquareEvent.configure do |events|
  events.all BillingEventLogger.new(Rails.logger)
  events.subscribe 'customer.created', CustomerCreated.new
end
```

### Subscribing to a namespace of event types

```ruby
SquareEvent.subscribe 'customer.' do |event|
  # Will be triggered for any customer.* events
end
```

## Securing your webhook endpoint

### Authenticating webhooks with signatures

Square will cryptographically sign webhook payloads with a signature that is included in a special header sent with the request. Verifying this signature lets your application properly authenticate the request originated from Square. SquareEvent mandates that this is used for every request. Please set the `signing_secret` and `notification_url` configuration values:

```ruby
SquareEvent.signing_secret = Rails.application.credentials.square[Rails.env][:webhook_secret]
SquareEvent.notification_url = Rails.application.credentials.square[Rails.env][:notification_url]
```

Please refer to Square's documentation for more details: https://developer.squareup.com/docs/webhooks-api/validate-notifications

### Sandbox and live mode

If you'd like to ignore particular webhook events (perhaps to ignore test webhooks in production, you can do so by returning `nil` in your custom `event_filter`. For example:

```ruby
SquareEvent.event_filter = lambda do |event|
  return nil if Rails.env.production? && !event.sandbox?
  event
end
```

## Without Rails

SquareEvent can be used outside of Rails applications as well. Here is a basic Sinatra implementation:

```ruby
require 'json'
require 'sinatra'
require 'stripe_event'

SquareEvent.signing_secret   = ENV['SQUARE_SIGNING_SECRET']
SquareEvent.notification_url = ENV['SQUARE_NOTIFICATION_URL']

SquareEvent.subscribe 'payment.created' do |event|
  # Look ma, no Rails!
end

post '/_billing_events' do
  data = JSON.parse(request.body.read, symbolize_names: true)
  SquareEvent.instrument(data)
  200
end
```

## Testing

Handling webhooks is a critical piece of modern billing systems. Verifying the behavior of SquareEvent subscribers can be done fairly easily by stubbing out the HTTP signature header used to authenticate the webhook request. Tools like [Webmock](https://github.com/bblimke/webmock) and [VCR](https://github.com/vcr/vcr) work well. [RequestBin](https://requestbin.com/) is great for collecting the payloads. For exploratory phases of development, [UltraHook](http://www.ultrahook.com/) and other tools can forward webhook requests directly to localhost. 

The Square ruby library does not currently offer an `Event` object to use to create or refer to webhook with, so their testing in Ruby is harder than with Stripe. 

### Maintainers

* [Andy Callaghan](https://github.com/acallaghan)

Special thanks to all the [contributors](https://github.com/jammed-org/square_event/graphs/contributors).

### Versioning

Semantic Versioning 2.0 as defined at <http://semver.org>.

### License

[MIT License](https://github.com/jammed-org/square_event/blob/master/LICENSE.md). Copyright 2020-2021 Andy Callaghan, Square work. Copyright 2012-2015 Integrallis Software original Stripe work.
