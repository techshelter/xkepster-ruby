# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xkepster::Resources::EmailAuth do
  let(:api_key) { "test_key" }
  let(:client) { Xkepster::Client.new(api_key: api_key, base_url: "https://api.xkepster.com") }
  let(:email_auth) { client.email_auth }

  describe "#register" do
    let(:email) { "user@example.com" }
    let(:group_id) { "group-uuid" }

    before do
      stub_request(:post, "https://api.xkepster.com/email_auths")
        .with(
          headers: {
            "X-Kepster-Key" => api_key,
            "Content-Type" => "application/vnd.api+json",
            "Accept" => "application/vnd.api+json"
          },
          body: {
            data: {
              type: "email_auths",
              attributes: { email: email },
              relationships: {
                group: { data: { type: "groups", id: group_id } }
              }
            }
          }
        )
        .to_return(
          status: 201,
          body: {
            data: {
              type: "email_auths",
              id: "email-auth-uuid",
              attributes: {
                status: "pending",
                inserted_at: "2025-11-19T14:30:00Z"
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "makes POST request to /email_auths" do
      email_auth.register(email: email, group_id: group_id)

      expect(WebMock).to have_requested(:post, "https://api.xkepster.com/email_auths")
        .with(body: hash_including(
          "data" => hash_including(
            "type" => "email_auths",
            "attributes" => hash_including("email" => email)
          )
        ))
    end
  end

  describe "#verify_token" do
    let(:email_auth_id) { "email-auth-uuid" }
    let(:token) { "magic-link-token" }
    let(:user_params) { { first_name: "Jane", last_name: "Smith" } }

    before do
      stub_request(:patch, "https://api.xkepster.com/email_auths/#{email_auth_id}/verify_token")
        .with(
          headers: {
            "X-Kepster-Key" => api_key,
            "Content-Type" => "application/vnd.api+json",
            "Accept" => "application/vnd.api+json"
          },
          body: {
            data: {
              type: "email_auths",
              id: email_auth_id,
              attributes: {
                token: token,
                user_params: user_params
              }
            }
          }
        )
        .to_return(
          status: 200,
          body: {
            data: {
              type: "email_auths",
              id: email_auth_id,
              attributes: {
                status: "verified"
              }
            },
            meta: {
              access_token: "token",
              refresh_token: "refresh"
            }
          }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "makes PATCH request to /email_auths/:id/verify_token" do
      email_auth.verify_token(email_auth_id: email_auth_id, token: token, user_params: user_params)

      expect(WebMock).to have_requested(:patch, "https://api.xkepster.com/email_auths/#{email_auth_id}/verify_token")
        .with(body: hash_including(
          "data" => hash_including(
            "type" => "email_auths",
            "id" => email_auth_id,
            "attributes" => hash_including("token" => token)
          )
        ))
    end
  end

  describe "#resend_magic_link" do
    let(:email_auth_id) { "email-auth-uuid" }

    before do
      stub_request(:patch, "https://api.xkepster.com/email_auths/#{email_auth_id}/resend_magic_link")
        .with(
          headers: {
            "X-Kepster-Key" => api_key,
            "Content-Type" => "application/vnd.api+json",
            "Accept" => "application/vnd.api+json"
          },
          body: {
            data: {
              type: "email_auths",
              id: email_auth_id,
              attributes: {}
            }
          }
        )
        .to_return(
          status: 200,
          body: {
            data: {
              type: "email_auths",
              id: email_auth_id,
              attributes: {
                status: "pending"
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "makes PATCH request to /email_auths/:id/resend_magic_link" do
      email_auth.resend_magic_link(email_auth_id)

      expect(WebMock).to have_requested(:patch, "https://api.xkepster.com/email_auths/#{email_auth_id}/resend_magic_link")
        .with(body: hash_including(
          "data" => hash_including(
            "type" => "email_auths",
            "id" => email_auth_id
          )
        ))
    end

    context "with machine token" do
      let(:machine_token) { "machine-token-123" }
      let(:machine_client) { Xkepster::Client.new(api_key: api_key, base_url: "https://api.xkepster.com", machine_token: machine_token) }
      let(:machine_email_auth) { machine_client.email_auth }

      before do
        stub_request(:patch, "https://api.xkepster.com/email_auths/#{email_auth_id}/resend_magic_link")
          .with(headers: { "X-Machine-Token" => machine_token })
          .to_return(
            status: 200,
            body: {
              data: {
                type: "email_auths",
                id: email_auth_id,
                attributes: { status: "pending" }
              }
            }.to_json,
            headers: { "Content-Type" => "application/vnd.api+json" }
          )
      end

      it "includes X-Machine-Token header" do
        machine_email_auth.resend_magic_link(email_auth_id)

        expect(WebMock).to have_requested(:patch, "https://api.xkepster.com/email_auths/#{email_auth_id}/resend_magic_link")
          .with(headers: { "X-Machine-Token" => machine_token })
      end
    end
  end
end

