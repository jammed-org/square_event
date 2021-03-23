module SquareEvent
  class Webhook

    # Initializes an webook Event object from a JSON payload.
    #
    # TODO: raise JSON::ParserError if the payload is not valid JSON, or
    # SignatureVerificationError if the signature verification fails.
    def self.construct_event(payload, signature, secret, notification_url, environment, timestamp)

      Signature.verify_header(payload, signature, secret, notification_url)

      data = JSON.parse(payload, symbolize_names: true)
      Event.construct_from(data, environment, timestamp)
    end

    module Signature
      # Computes a webhook signature given payload, and a signing secret
      def self.verify_header(payload, signature, secret, notification_url)
        combined_payload = notification_url + payload
        digest = OpenSSL::Digest.new('sha1')
        hmac = OpenSSL::HMAC.digest(digest, secret, combined_payload)

        # stripping the newline off the end
        found_signature = Base64.encode64(hmac).strip

        if found_signature != signature
          raise SignatureVerificationError.new(
            "Signature was incorrect for webhook at #{notification_url}",
            http_body: payload
          )
        end
      end

    end
  end
end
