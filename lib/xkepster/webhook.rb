# frozen_string_literal: true

require "openssl"
require "json"

module Xkepster
  class Webhook
    OTP_EVENT = "otp"
    MAGIC_LINK_EVENT = "magic_link"

    attr_reader :webhook_secret

    def initialize(webhook_secret: nil)
      @webhook_secret = webhook_secret || Xkepster.config.webhook_secret
    end

    # Verifies webhook signature using HMAC-SHA256
    #
    # @param signature [String] The X-Webhook-Signature header value
    # @param body [String] The raw request body (must be the exact raw JSON string, not parsed params)
    # @return [Boolean] True if signature is valid, false otherwise
    def verify_signature(signature, body)
      return false if webhook_secret.nil? || signature.nil? || body.nil?

      raise ArgumentError, "Body must be a raw string (use request.raw_post, not params)" unless body.is_a?(String)

      expected_signature = compute_signature(body)
      secure_compare(signature, expected_signature)
    end

    # Verifies and parses webhook payload
    #
    # @param signature [String] The X-Webhook-Signature header value
    # @param body [String] The raw request body (must be the exact raw JSON string, not parsed params)
    # @param event_type [String] Expected webhook event type from X-Webhook-Event header
    # @return [Hash] Parsed webhook payload
    # @raise [WebhookVerificationError] If signature verification fails
    # @raise [InvalidWebhookError] If payload is invalid
    def verify_and_parse(signature, body, event_type = nil)
      unless verify_signature(signature, body)
        raise WebhookVerificationError, build_verification_error_message(signature, body)
      end

      payload = JSON.parse(body)
      validate_payload_structure(payload, event_type)
      payload
    rescue JSON::ParserError => e
      raise InvalidWebhookError, "Invalid JSON payload: #{e.message}"
    end

    # Parses an OTP delivery webhook
    #
    # @param signature [String] The X-Webhook-Signature header value
    # @param body [String] The raw request body
    # @return [Hash] OTP webhook data
    def parse_otp_webhook(signature, body)
      payload = verify_and_parse(signature, body, OTP_EVENT)
      {
        type: payload["type"],
        recipient: payload["recipient"],
        code: payload["code"],
        timestamp: payload["timestamp"],
        validity_seconds: payload["validity_seconds"]
      }
    end

    # Parses a magic link delivery webhook
    #
    # @param signature [String] The X-Webhook-Signature header value
    # @param body [String] The raw request body
    # @return [Hash] Magic link webhook data
    def parse_magic_link_webhook(signature, body)
      payload = verify_and_parse(signature, body, MAGIC_LINK_EVENT)
      {
        type: payload["type"],
        recipient: payload["recipient"],
        link: payload["link"],
        timestamp: payload["timestamp"],
        validity_seconds: payload["validity_seconds"]
      }
    end

    private

    def compute_signature(body)
      OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body)
    end

    def build_verification_error_message(signature, body)
      msg = "Invalid webhook signature"

      if webhook_secret.nil?
        msg += " (webhook_secret is not configured)"
      elsif signature.nil?
        msg += " (X-Webhook-Signature header is missing)"
      elsif body.nil?
        msg += " (request body is missing - use request.raw_post)"
      elsif !body.is_a?(String)
        msg += " (body must be raw string, got #{body.class} - use request.raw_post, not params)"
      else
        expected = compute_signature(body)
        msg += " (expected: #{expected[0..15]}..., got: #{signature[0..15]}...)" if signature.length >= 16
      end

      msg
    end

    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      result = 0
      a.bytes.zip(b.bytes) { |x, y| result |= x ^ y }
      result == 0
    end

    def validate_payload_structure(payload, expected_event_type = nil)
      raise InvalidWebhookError, "Payload must be a JSON object" unless payload.is_a?(Hash)

      required_fields = %w[type timestamp]
      missing_fields = required_fields - payload.keys
      raise InvalidWebhookError, "Missing required fields: #{missing_fields.join(", ")}" unless missing_fields.empty?

      if expected_event_type && payload["type"] != expected_event_type
        raise InvalidWebhookError, "Expected event type #{expected_event_type}, got #{payload["type"]}"
      end

      case payload["type"]
      when OTP_EVENT
        validate_otp_payload(payload)
      when MAGIC_LINK_EVENT
        validate_magic_link_payload(payload)
      else
        raise InvalidWebhookError, "Unknown webhook event type: #{payload["type"]}"
      end
    end

    def validate_otp_payload(payload)
      otp_fields = %w[recipient code validity_seconds]
      missing_fields = otp_fields - payload.keys
      unless missing_fields.empty?
        raise InvalidWebhookError,
              "OTP webhook missing required fields: #{missing_fields.join(", ")}"
      end

      raise InvalidWebhookError, "Invalid OTP code format" unless payload["code"]&.match?(/\A\d{6}\z/)
      raise InvalidWebhookError, "validity_seconds must be an integer" unless payload["validity_seconds"].is_a?(Integer)
    end

    def validate_magic_link_payload(payload)
      link_fields = %w[recipient link validity_seconds]
      missing_fields = link_fields - payload.keys
      unless missing_fields.empty?
        raise InvalidWebhookError,
              "Magic link webhook missing required fields: #{missing_fields.join(", ")}"
      end

      raise InvalidWebhookError, "Invalid magic link URL format" unless payload["link"]&.start_with?("http")
      raise InvalidWebhookError, "validity_seconds must be an integer" unless payload["validity_seconds"].is_a?(Integer)
    end
  end
end
