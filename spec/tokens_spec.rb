# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xkepster::Resources::Tokens do
  let(:api_key) { "test_key" }
  let(:client) { Xkepster::Client.new(api_key: api_key, base_url: "https://api.xkepster.com") }
  let(:tokens) { client.tokens }
  let(:user_id) { "user-uuid" }
  let(:expires_at) { Time.utc(2026, 6, 11, 12, 0, 0) }

  describe "#create" do
    before do
      stub_request(:post, "https://api.xkepster.com/tokens")
        .with(
          body: {
            data: {
              type: "tokens",
              attributes: {
                expires_at: "2026-06-11T12:00:00Z",
                claims: { scope: "read" }
              },
              relationships: {
                user: { data: { type: "users", id: user_id } }
              }
            }
          }.to_json
        )
        .to_return(
          status: 201,
          body: { data: { type: "tokens", id: "token-uuid" } }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "creates a token with a user relationship and coerced expires_at" do
      result = tokens.create(user_id, expires_at: expires_at, claims: { scope: "read" })

      expect(result.dig("data", "id")).to eq("token-uuid")
    end

    it "accepts expires_at as a string" do
      stub_request(:post, "https://api.xkepster.com/tokens")
        .with(
          body: {
            data: {
              type: "tokens",
              attributes: { expires_at: "2026-12-31T00:00:00Z" },
              relationships: {
                user: { data: { type: "users", id: user_id } }
              }
            }
          }.to_json
        )
        .to_return(status: 201, body: { data: { type: "tokens", id: "token-uuid" } }.to_json)

      tokens.create(user_id, expires_at: "2026-12-31T00:00:00Z")
    end

    it "raises for invalid expires_at types" do
      expect { tokens.create(user_id, expires_at: 123) }
        .to raise_error(ArgumentError, /expires_at must be/)
    end
  end
end
