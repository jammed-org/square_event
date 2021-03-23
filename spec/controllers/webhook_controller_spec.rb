require 'rails_helper'
require 'spec_helper'

describe SquareEvent::WebhookController, type: :controller do
  let(:secret1) { 'secret1' }
  let(:secret2) { 'secret2' }
  let(:url1)    { 'https://example.com/webhook' }
  let(:url2)    { 'https://another.com/webhook' }
  let(:env)     { 'Sandbox' }

  let(:payment_created) { stub_event('evt_payment_created') }

  def stub_event(identifier)
    JSON.parse(File.read("spec/support/fixtures/#{identifier}.json"))
  end

  def generate_signature(params, secret, url)
    payload = params.to_json
    combined_payload = url + payload
    digest = OpenSSL::Digest.new('sha1')
    hmac = OpenSSL::HMAC.digest(digest, secret, combined_payload)

    Base64.encode64(hmac).strip
  end

  def webhook(signature, params, environment='Sandbox')
    request.headers['X-Square-Signature'] = signature
    request.headers['square-environment'] = environment
    request.env['RAW_POST_DATA'] = params.to_json # works with Rails 3, 4, or 5
    post :event, body: params.to_json
  end

  def webhook_with_signature(params, secret = secret1, url = url1, environment = env)
    webhook generate_signature(params, secret, url), params, environment
  end

  routes { SquareEvent::Engine.routes }

  context "without a signing secret" do
    before(:each) { SquareEvent.signing_secret = nil }

    it "denies invalid signature" do
      webhook "invalid signature", payment_created
      expect(response.code).to eq '400'
    end

    it "denies valid signature" do
      webhook_with_signature payment_created
      expect(response.code).to eq '400'
    end
  end

  context "without a notification URL" do
    before(:each) { SquareEvent.notification_url = nil }

    it "denies invalid signature" do
      webhook "invalid signature", payment_created
      expect(response.code).to eq '400'
    end

    it "denies valid signature" do
      webhook_with_signature payment_created
      expect(response.code).to eq '400'
    end
  end

  context "with a signing secret and notification url" do
    before(:each) do
      SquareEvent.signing_secret = secret1
      SquareEvent.notification_url = url1
    end

    it "denies missing signature" do
      webhook nil, payment_created
      expect(response.code).to eq '400'
    end

    it "denies invalid signature" do
      webhook "invalid signature", payment_created
      expect(response.code).to eq '400'
    end

    it "denies signature from wrong secret" do
      webhook_with_signature payment_created, 'bogus'
      expect(response.code).to eq '400'
    end

    it "succeeds with valid signature from correct secret" do
      webhook_with_signature payment_created, secret1, url1
      expect(response.code).to eq '200'
    end

    it "succeeds with valid event data" do
      count = 0
      SquareEvent.subscribe('payment.created') { |evt| count += 1 }

      webhook_with_signature payment_created

      expect(response.code).to eq '200'
      expect(count).to eq 1
    end

    it "succeeds when the event_filter returns nil (simulating an ignored webhook event)" do
      count = 0
      SquareEvent.event_filter = lambda { |event| return nil }
      SquareEvent.subscribe('payment.created') { |evt| count += 1 }

      webhook_with_signature payment_created

      expect(response.code).to eq '200'
      expect(count).to eq 0
    end

    it "ensures user-generated exceptions pass through" do
      SquareEvent.subscribe('payment.created') { |evt| raise SquareEventError, "testing" }

      expect { webhook_with_signature(payment_created) }.to raise_error(SquareEventError, /testing/)
    end

    context 'given the production environment' do
      let(:env) { 'Production' }
     

    end
     
  end

  class SquareEventError < Exception
  end
end
