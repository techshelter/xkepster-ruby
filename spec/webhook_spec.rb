# frozen_string_literal: true

require "spec_helper"
require "openssl"

RSpec.describe Xkpester::Webhook do
  let(:webhook_secret) { "test_webhook_secret_123" }
  let(:webhook) { described_class.new(webhook_secret: webhook_secret) }
  let(:timestamp) { Time.now.to_i }
  
  let(:otp_payload) do
    {
      "type" => "otp",
      "recipient" => "+1234567890",
      "code" => "123456",
      "tenant" => "test-tenant",
      "timestamp" => timestamp
    }
  end
  
  let(:magic_link_payload) do
    {
      "type" => "magic_link", 
      "recipient" => "user@example.com",
      "link" => "https://example.com/magic-link",
      "tenant" => "test-tenant",
      "timestamp" => timestamp
    }
  end

  before do
    # Reset configuration before each test
    Xkpester.reset_configuration!
  end

  describe "#initialize" do
    context "when webhook_secret is provided" do
      it "uses the provided secret" do
        webhook = described_class.new(webhook_secret: "custom_secret")
        expect(webhook.webhook_secret).to eq("custom_secret")
      end
    end

    context "when webhook_secret is not provided" do
      it "uses the secret from configuration" do
        Xkpester.configure do |config|
          config.webhook_secret = "config_secret"
        end
        
        webhook = described_class.new
        expect(webhook.webhook_secret).to eq("config_secret")
      end
    end

    context "when no secret is configured" do
      it "has nil webhook_secret" do
        webhook = described_class.new
        expect(webhook.webhook_secret).to be_nil
      end
    end
  end

  describe "#verify_signature" do
    let(:body) { '{"test": "data"}' }
    let(:valid_signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }

    context "with valid signature" do
      it "returns true" do
        expect(webhook.verify_signature(valid_signature, body)).to be true
      end
    end

    context "with invalid signature" do
      it "returns false" do
        expect(webhook.verify_signature("invalid_signature", body)).to be false
      end
    end

    context "with nil webhook_secret" do
      let(:webhook) { described_class.new(webhook_secret: nil) }
      
      it "returns false" do
        expect(webhook.verify_signature(valid_signature, body)).to be false
      end
    end

    context "with nil signature" do
      it "returns false" do
        expect(webhook.verify_signature(nil, body)).to be false
      end
    end

    context "with nil body" do
      it "returns false" do
        expect(webhook.verify_signature(valid_signature, nil)).to be false
      end
    end

    context "with empty signature" do
      it "returns false" do
        expect(webhook.verify_signature("", body)).to be false
      end
    end
  end

  describe "#verify_and_parse" do
    let(:body) { otp_payload.to_json }
    let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }

    context "with valid signature and payload" do
      it "returns parsed payload" do
        result = webhook.verify_and_parse(signature, body)
        expect(result).to eq(otp_payload)
      end
    end

    context "with invalid signature" do
      it "raises WebhookVerificationError" do
        expect {
          webhook.verify_and_parse("invalid_signature", body)
        }.to raise_error(Xkpester::WebhookVerificationError, "Invalid webhook signature")
      end
    end

    context "with invalid JSON" do
      let(:body) { "invalid json" }
      let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      
      it "raises InvalidWebhookError" do
        expect {
          webhook.verify_and_parse(signature, body)
        }.to raise_error(Xkpester::InvalidWebhookError, /Invalid JSON payload/)
      end
    end

    context "with missing required fields" do
      let(:invalid_payload) { { "type" => "otp" } }
      let(:body) { invalid_payload.to_json }
      let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      
      it "raises InvalidWebhookError" do
        expect {
          webhook.verify_and_parse(signature, body)
        }.to raise_error(Xkpester::InvalidWebhookError, /Missing required fields/)
      end
    end

    context "with unknown event type" do
      let(:invalid_payload) do
        {
          "type" => "unknown_event",
          "tenant" => "test-tenant", 
          "timestamp" => timestamp
        }
      end
      let(:body) { invalid_payload.to_json }
      let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      
      it "raises InvalidWebhookError" do
        expect {
          webhook.verify_and_parse(signature, body)
        }.to raise_error(Xkpester::InvalidWebhookError, /Unknown webhook event type/)
      end
    end

    context "with expected event type mismatch" do
      it "raises InvalidWebhookError" do
        expect {
          webhook.verify_and_parse(signature, body, "magic_link")
        }.to raise_error(Xkpester::InvalidWebhookError, /Expected event type magic_link, got otp/)
      end
    end
  end

  describe "#parse_otp_webhook" do
    let(:body) { otp_payload.to_json }
    let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }

    context "with valid OTP webhook" do
      it "returns parsed OTP data" do
        result = webhook.parse_otp_webhook(signature, body)
        
        expect(result).to eq({
          type: "otp",
          recipient: "+1234567890", 
          code: "123456",
          tenant: "test-tenant",
          timestamp: timestamp
        })
      end
    end

    context "with magic link webhook" do
      let(:body) { magic_link_payload.to_json }
      let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      
      it "raises InvalidWebhookError" do
        expect {
          webhook.parse_otp_webhook(signature, body)
        }.to raise_error(Xkpester::InvalidWebhookError, "Expected OTP webhook, got magic_link")
      end
    end

    context "with missing OTP fields" do
      let(:incomplete_payload) do
        {
          "type" => "otp",
          "tenant" => "test-tenant",
          "timestamp" => timestamp
        }
      end
      let(:body) { incomplete_payload.to_json }
      let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      
      it "raises InvalidWebhookError" do
        expect {
          webhook.parse_otp_webhook(signature, body)
        }.to raise_error(Xkpester::InvalidWebhookError, /OTP webhook missing required fields/)
      end
    end

    context "with invalid OTP code format" do
      let(:invalid_otp_payload) do
        otp_payload.merge("code" => "abc123")
      end
      let(:body) { invalid_otp_payload.to_json }
      let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      
      it "raises InvalidWebhookError" do
        expect {
          webhook.parse_otp_webhook(signature, body)
        }.to raise_error(Xkpester::InvalidWebhookError, "Invalid OTP code format")
      end
    end
  end

  describe "#parse_magic_link_webhook" do
    let(:body) { magic_link_payload.to_json }
    let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }

    context "with valid magic link webhook" do
      it "returns parsed magic link data" do
        result = webhook.parse_magic_link_webhook(signature, body)
        
        expect(result).to eq({
          type: "magic_link",
          recipient: "user@example.com",
          link: "https://example.com/magic-link", 
          tenant: "test-tenant",
          timestamp: timestamp
        })
      end
    end

    context "with OTP webhook" do
      let(:body) { otp_payload.to_json }
      let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      
      it "raises InvalidWebhookError" do
        expect {
          webhook.parse_magic_link_webhook(signature, body)
        }.to raise_error(Xkpester::InvalidWebhookError, "Expected magic link webhook, got otp")
      end
    end

    context "with missing magic link fields" do
      let(:incomplete_payload) do
        {
          "type" => "magic_link",
          "tenant" => "test-tenant",
          "timestamp" => timestamp
        }
      end
      let(:body) { incomplete_payload.to_json }
      let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      
      it "raises InvalidWebhookError" do
        expect {
          webhook.parse_magic_link_webhook(signature, body)
        }.to raise_error(Xkpester::InvalidWebhookError, /Magic link webhook missing required fields/)
      end
    end

    context "with invalid magic link URL format" do
      let(:invalid_magic_link_payload) do
        magic_link_payload.merge("link" => "invalid-url")
      end
      let(:body) { invalid_magic_link_payload.to_json }
      let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      
      it "raises InvalidWebhookError" do
        expect {
          webhook.parse_magic_link_webhook(signature, body)
        }.to raise_error(Xkpester::InvalidWebhookError, "Invalid magic link URL format")
      end
    end
  end

  describe "constants" do
    it "defines OTP_EVENT constant" do
      expect(described_class::OTP_EVENT).to eq("otp")
    end

    it "defines MAGIC_LINK_EVENT constant" do
      expect(described_class::MAGIC_LINK_EVENT).to eq("magic_link")
    end
  end

  describe "security considerations" do
    describe "timing attack protection" do
      let(:body) { '{"test": "data"}' }
      let(:correct_signature) { OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body) }
      let(:incorrect_signature) { "a" * correct_signature.length }
      
      it "uses constant-time comparison" do
        # This test ensures that the secure_compare method is being used
        # We can't easily test timing directly in a unit test, but we can verify
        # that different signatures of the same length are handled consistently
        expect(webhook.verify_signature(correct_signature, body)).to be true
        expect(webhook.verify_signature(incorrect_signature, body)).to be false
      end
    end

    describe "signature validation edge cases" do
      let(:body) { '{"test": "data"}' }
      
      it "handles signatures of different lengths" do
        short_signature = "short"
        long_signature = "very_long_signature_that_exceeds_expected_length"
        
        expect(webhook.verify_signature(short_signature, body)).to be false
        expect(webhook.verify_signature(long_signature, body)).to be false
      end
    end
  end
end