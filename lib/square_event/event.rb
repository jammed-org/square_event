module SquareEvent
  class Event
    attr_reader :type, :merchant_id, :event_id, :data, :payload, :environment, :initial_delivery_timestamp

    def to_h
      {
        type: type,
        merchant_id: merchant_id,
        event_id: event_id,
        data: data,
        environment: environment,
        initial_delivery_timestamp: initial_delivery_timestamp
      }
    end

    def self.construct_from(payload, environment, timestamp)
      type        = payload[:type]
      merchant_id = payload[:merchant_id]
      event_id    = payload[:event_id]
      data        = payload[:data]

      new(type, merchant_id, event_id, data, payload, environment, timestamp)
    end

    def initialize(type, merchant_id, event_id, data, payload, environment, timestamp)
      @type = type
      @merchant_id = merchant_id
      @event_id = event_id
      @data = data
      @environment = environment
      @initial_delivery_timestamp = timestamp
    end

    def livemode
      environment != 'Sandbox'
    end
    alias_method :livemode?, :livemode

    def sandbox
      environment == 'Sandbox'
    end
    alias_method :sandbox?, :sandbox

  end
end
