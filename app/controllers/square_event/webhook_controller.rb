require 'square_event/webhook'
require 'square_event/errors'

module SquareEvent
  class WebhookController < ActionController::Base
    SECRET_ERROR       = 'There was no webhook signing secret provided for this webhook'.freeze
    NOTIFICATION_ERROR = 'There was no webhook notification URL provided for this webhook. Make sure it exactly matches and starts with https://'.freeze

    if Rails.application.config.action_controller.default_protect_from_forgery
      skip_before_action :verify_authenticity_token
    end

    def event
      SquareEvent.instrument(verified_event)
      head :ok
    rescue SquareEvent::SignatureVerificationError => e
      log_error(e)
      head :bad_request
    end

    private

    def verified_event
      payload          = request.raw_post
      signature        = request.headers['X-Square-Signature']
      environment      = request.headers['square-environment']
      timestamp        = request.headers['square-initial-delivery-timestamp']
      secret           = SquareEvent.signing_secret
      notification_url = SquareEvent.notification_url

      if secret.nil?
        raise SignatureVerificationError.new(SECRET_ERROR)
      end

      if notification_url.nil?
        raise SignatureVerificationError.new(NOTIFICATION_ERROR)
      end

      SquareEvent::Webhook.construct_event(payload, signature, secret, notification_url, environment, timestamp)
    end

    def log_error(e)
      logger.error e.message
      e.backtrace.each { |line| logger.error "  #{line}" }
    end
  end
end
