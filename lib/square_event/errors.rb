module SquareEvent
  class SquareEventError < StandardError

    attr_reader :message
    attr_reader :http_body

    def initialize(message = nil, http_body: nil)
      @message = message
      @http_body = http_body
    end

  end

  class SignatureVerificationError < SquareEventError
  end
end
