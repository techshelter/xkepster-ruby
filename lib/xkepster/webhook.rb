# frozen_string_literal: true

require "openssl"

module Xkepster
  class Webhook
    # Webhook event types from the API specification
    OTP_EVENT = "otp"
    MAGIC_LINK_EVENT = "magic_link"

    attr_reader :webhook_secret

    def initialize(webhook_secret: nil)
      @webhook_secret = webhook_secret || Xkepster.config.webhook_secret
    end

    # Verifies webhook signature using HMAC-SHA256
    #
    # @param signature [String] The X-Webhook-Signature header value
    # @param body [String] The raw request body
    # @return [Boolean] True if signature is valid, false otherwise
    def verify_signature(signature, body)
      return false if webhook_secret.nil? || signature.nil? || body.nil?

      expected_signature = compute_signature(body)
      secure_compare(signature, expected_signature)
    end

    # Verifies and parses webhook payload
    #
    # @param signature [String] The X-Webhook-Signature header value  
    # @param body [String] The raw request body
    # @param event_type [String] Expected webhook event type from X-Webhook-Event header
    # @return [Hash] Parsed webhook payload
    # @raise [WebhookVerificationError] If signature verification fails
    # @raise [InvalidWebhookError] If payload is invalid
    def verify_and_parse(signature, body, event_type = nil)
      unless verify_signature(signature, body)
        raise WebhookVerificationError, "Invalid webhook signature"
      end

      begin
        payload = JSON.parse(body)
      rescue JSON::ParserError => e
        raise InvalidWebhookError, "Invalid JSON payload: #{e.message}"
      end

      validate_payload_structure(payload, event_type)
      payload
    end

    # Parses an OTP delivery webhook
    #
    # @param signature [String] The X-Webhook-Signature header value
    # @param body [String] The raw request body  
    # @return [Hash] OTP webhook data
    def parse_otp_webhook(signature, body)
      payload = verify_and_parse(signature, body)
      
      unless payload["type"] == OTP_EVENT
        raise InvalidWebhookError, "Expected OTP webhook, got #{payload['type']}"
      end

      {
        type: payload["type"],
        recipient: payload["recipient"],
        code: payload["code"], 
        tenant: payload["tenant"],
        timestamp: payload["timestamp"]
      }
    end

    # Parses a magic link delivery webhook
    #
    # @param signature [String] The X-Webhook-Signature header value
    # @param body [String] The raw request body
    # @return [Hash] Magic link webhook data  
    def parse_magic_link_webhook(signature, body)
      payload = verify_and_parse(signature, body)

      unless payload["type"] == MAGIC_LINK_EVENT
        raise InvalidWebhookError, "Expected magic link webhook, got #{payload['type']}"
      end

      {
        type: payload["type"],
        recipient: payload["recipient"],
        link: payload["link"],
        tenant: payload["tenant"], 
        timestamp: payload["timestamp"]
      }
    end

    private

    def compute_signature(body)
      OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body)
    end

    # Constant-time string comparison to prevent timing attacks
    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize
      
      result = 0
      a.bytes.zip(b.bytes) { |x, y| result |= x ^ y }
      result == 0
    end

    def validate_payload_structure(payload, expected_event_type = nil)
      unless payload.is_a?(Hash)
        raise InvalidWebhookError, "Payload must be a JSON object"
      end

      required_fields = %w[type tenant timestamp]
      missing_fields = required_fields - payload.keys
      unless missing_fields.empty?
        raise InvalidWebhookError, "Missing required fields: #{missing_fields.join(', ')}"
      end

      if expected_event_type && payload["type"] != expected_event_type
        raise InvalidWebhookError, "Expected event type #{expected_event_type}, got #{payload['type']}"
      end

      case payload["type"]
      when OTP_EVENT
        validate_otp_payload(payload)
      when MAGIC_LINK_EVENT
        validate_magic_link_payload(payload)
      else
        raise InvalidWebhookError, "Unknown webhook event type: #{payload['type']}"
      end
    end

    def validate_otp_payload(payload)
      otp_fields = %w[recipient code]
      missing_fields = otp_fields - payload.keys
      unless missing_fields.empty?
        raise InvalidWebhookError, "OTP webhook missing required fields: #{missing_fields.join(', ')}"
      end

      unless payload["code"]&.match?(/\A\d{6}\z/)
        raise InvalidWebhookError, "Invalid OTP code format"
      end
    end

    def validate_magic_link_payload(payload)
      link_fields = %w[recipient link]
      missing_fields = link_fields - payload.keys
      unless missing_fields.empty?
        raise InvalidWebhookError, "Magic link webhook missing required fields: #{missing_fields.join(', ')}"
      end

      unless payload["link"]&.start_with?("http")
        raise InvalidWebhookError, "Invalid magic link URL format"
      end
    end
  end
end