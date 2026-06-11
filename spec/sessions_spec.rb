# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xkepster::Resources::Sessions do
  let(:api_key) { "test_key" }
  let(:client) { Xkepster::Client.new(api_key: api_key, base_url: "https://api.xkepster.com") }
  let(:sessions) { client.sessions }
  let(:user_id) { "user-uuid" }

  describe "#create" do
    before do
      stub_request(:post, "https://api.xkepster.com/sessions")
        .with(
          body: {
            data: {
              type: "sessions",
              attributes: { device: "iphone" },
              relationships: {
                user: { data: { type: "users", id: user_id } }
              }
            }
          }.to_json
        )
        .to_return(
          status: 201,
          body: { data: { type: "sessions", id: "session-uuid" } }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "creates a session with a user relationship" do
      result = sessions.create(user_id, attributes: { device: "iphone" })

      expect(result.dig("data", "id")).to eq("session-uuid")
    end
  end
end
