require 'coveralls'
Coveralls.wear!

require 'webmock/rspec'
require File.expand_path('../../lib/square_event', __FILE__)
Dir[File.expand_path('../spec/support/**/*.rb', __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    @signing_secrets = SquareEvent.signing_secret
    @event_filter = SquareEvent.event_filter
    @notifier = SquareEvent.backend.notifier
    SquareEvent.backend.notifier = @notifier.class.new
  end

  config.after do
    SquareEvent.signing_secret = @signing_secret
    SquareEvent.event_filter = @event_filter
    SquareEvent.backend.notifier = @notifier
  end
end
