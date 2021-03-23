require 'spec_helper'

describe SquareEvent do
  let(:events) { [] }
  let(:subscriber) { ->(evt){ events << evt } }
  let(:payment_created) { SquareEvent::Event.construct_from(id: 'evt_payment_created', type: 'charge.succeeded') }
  let(:charge_failed) { SquareEvent::Event.construct_from(id: 'evt_charge_failed', type: 'charge.failed') }
  let(:card_created) { SquareEvent::Event.construct_from(id: 'event_card_created', type: 'customer.card.created') }
  let(:card_updated) { SquareEvent::Event.construct_from(id: 'event_card_updated', type: 'customer.card.updated') }

  describe ".configure" do
    it "yields itself to the block" do
      yielded = nil
      SquareEvent.configure { |events| yielded = events }
      expect(yielded).to eq SquareEvent
    end

    it "requires a block argument" do
      expect { SquareEvent.configure }.to raise_error ArgumentError
    end

    describe ".setup - deprecated" do
      it "evaluates the block in its own context" do
        ctx = nil
        SquareEvent.setup { ctx = self }
        expect(ctx).to eq SquareEvent
      end
    end
  end

  describe "subscribing to a specific event type" do
    context "with a block subscriber" do
      it "calls the subscriber with the retrieved event" do
        SquareEvent.subscribe('charge.succeeded', &subscriber)
        SquareEvent.instrument(payment_created)

        expect(events).to eq [payment_created]
      end
    end

    context "with a subscriber that responds to #call" do
      it "calls the subscriber with the retrieved event" do
        SquareEvent.subscribe('charge.succeeded', subscriber)
        SquareEvent.instrument(payment_created)

        expect(events).to eq [payment_created]
      end
    end
  end

  describe "subscribing to a namespace of event types" do
    context "with a block subscriber" do
      it "calls the subscriber with any events in the namespace" do
        SquareEvent.subscribe('customer.card', &subscriber)

        SquareEvent.instrument(card_created)
        SquareEvent.instrument(card_updated)

        expect(events).to eq [card_created, card_updated]
      end
    end

    context "with a subscriber that responds to #call" do
      it "calls the subscriber with any events in the namespace" do
        SquareEvent.subscribe('customer.card.', subscriber)

        SquareEvent.instrument(card_updated)
        SquareEvent.instrument(card_created)

        expect(events).to eq [card_updated, card_created]
      end
    end
  end

  describe "subscribing to all event types" do
    context "with a block subscriber" do
      it "calls the subscriber with all retrieved events" do
        SquareEvent.all(&subscriber)

        SquareEvent.instrument(payment_created)
        SquareEvent.instrument(charge_failed)

        expect(events).to eq [payment_created, charge_failed]
      end
    end

    context "with a subscriber that responds to #call" do
      it "calls the subscriber with all retrieved events" do
        SquareEvent.all(subscriber)

        SquareEvent.instrument(payment_created)
        SquareEvent.instrument(charge_failed)

        expect(events).to eq [payment_created, charge_failed]
      end
    end
  end

  describe ".listening?" do
    it "returns true when there is a subscriber for a matching event type" do
      SquareEvent.subscribe('customer.', &subscriber)

      expect(SquareEvent.listening?('customer.card')).to be true
      expect(SquareEvent.listening?('customer.')).to be true
    end

    it "returns false when there is not a subscriber for a matching event type" do
      SquareEvent.subscribe('customer.', &subscriber)

      expect(SquareEvent.listening?('account')).to be false
    end

    it "returns true when a subscriber is subscribed to all events" do
      SquareEvent.all(&subscriber)

      expect(SquareEvent.listening?('customer.')).to be true
      expect(SquareEvent.listening?('account')).to be true
    end
  end

  describe SquareEvent::NotificationAdapter do
    let(:adapter) { SquareEvent.adapter }

    it "calls the subscriber with the last argument" do
      expect(subscriber).to receive(:call).with(:last)

      adapter.call(subscriber).call(:first, :last)
    end
  end

  describe SquareEvent::Namespace do
    let(:namespace) { SquareEvent.namespace }

    describe "#call" do
      it "prepends the namespace to a given string" do
        expect(namespace.call('foo.bar')).to eq 'square_event.foo.bar'
      end

      it "returns the namespace given no arguments" do
        expect(namespace.call).to eq 'square_event.'
      end
    end

    describe "#to_regexp" do
      it "matches namespaced strings" do
        expect(namespace.to_regexp('foo.bar')).to match namespace.call('foo.bar')
      end

      it "matches all namespaced strings given no arguments" do
        expect(namespace.to_regexp).to match namespace.call('foo.bar')
      end
    end
  end
end
