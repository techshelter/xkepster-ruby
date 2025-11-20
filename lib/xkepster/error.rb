# frozen_string_literal: true

module Xkepster
  Error = Class.new(StandardError)

  ApiError = Class.new(Error)
  AuthenticationError = Class.new(ApiError)
  NotFoundError = Class.new(ApiError)
  RateLimitError = Class.new(ApiError)
  ValidationError = Class.new(ApiError)
  ServerError = Class.new(ApiError)
  ConnectionError = Class.new(Error)
  TimeoutError = Class.new(Error)
  ResponseParsingError = Class.new(Error)
  WebhookVerificationError = Class.new(Error)
  InvalidWebhookError = Class.new(Error)

  class ApiError
    attr_reader :status, :code, :details

    def initialize(message, status: nil, code: nil, details: nil)
      super(message)
      @status = status
      @code = code
      @details = details
    end
  end
end