# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xkepster::Resources::SmsAuth do
  let(:api_key) { "test_key" }
  let(:client) { Xkepster::Client.new(api_key: api_key, base_url: "https://api.xkepster.com") }
  let(:sms_auth) { client.sms_auth }

  describe "#register" do
    let(:phone_number) { "+1234567890" }
    let(:group_id) { "group-uuid" }

    before do
      stub_request(:post, "https://api.xkepster.com/sms_auths")
        .with(
          headers: {
            "X-Kepster-Key" => api_key,
            "Content-Type" => "application/vnd.api+json",
            "Accept" => "application/vnd.api+json"
          },
          body: {
            data: {
              type: "sms_auths",
              attributes: { phone_number: phone_number },
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
              type: "sms_auths",
              id: "sms-auth-uuid",
              attributes: {
                status: "pending",
                inserted_at: "2025-11-19T14:30:00Z"
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "makes POST request to /sms_auths" do
      sms_auth.register(phone_number: phone_number, group_id: group_id)

      expect(WebMock).to have_requested(:post, "https://api.xkepster.com/sms_auths")
        .with(body: hash_including(
          "data" => hash_including(
            "type" => "sms_auths",
            "attributes" => hash_including("phone_number" => phone_number)
          )
        ))
    end
  end

  describe "#verify_otp" do
    let(:sms_auth_id) { "sms-auth-uuid" }
    let(:otp) { "123456" }
    let(:user_params) { { first_name: "John", last_name: "Doe" } }

    before do
      stub_request(:patch, "https://api.xkepster.com/sms_auths/#{sms_auth_id}/verify_otp")
        .with(
          headers: {
            "X-Kepster-Key" => api_key,
            "Content-Type" => "application/vnd.api+json",
            "Accept" => "application/vnd.api+json"
          },
          body: {
            data: {
              type: "sms_auths",
              id: sms_auth_id,
              attributes: {
                otp: otp,
                user_params: user_params
              }
            }
          }
        )
        .to_return(
          status: 200,
          body: {
            data: {
              type: "sms_auths",
              id: sms_auth_id,
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

    it "makes PATCH request to /sms_auths/:id/verify_otp" do
      sms_auth.verify_otp(sms_auth_id: sms_auth_id, otp: otp, user_params: user_params)

      expect(WebMock).to have_requested(:patch, "https://api.xkepster.com/sms_auths/#{sms_auth_id}/verify_otp")
        .with(body: hash_including(
          "data" => hash_including(
            "type" => "sms_auths",
            "id" => sms_auth_id,
            "attributes" => hash_including("otp" => otp)
          )
        ))
    end
  end

  describe "#resend_otp" do
    let(:sms_auth_id) { "sms-auth-uuid" }

    before do
      stub_request(:patch, "https://api.xkepster.com/sms_auths/#{sms_auth_id}/resend_otp")
        .with(
          headers: {
            "X-Kepster-Key" => api_key,
            "Content-Type" => "application/vnd.api+json",
            "Accept" => "application/vnd.api+json"
          },
          body: {
            data: {
              type: "sms_auths",
              id: sms_auth_id,
              attributes: {}
            }
          }
        )
        .to_return(
          status: 200,
          body: {
            data: {
              type: "sms_auths",
              id: sms_auth_id,
              attributes: {
                status: "pending"
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "makes PATCH request to /sms_auths/:id/resend_otp" do
      sms_auth.resend_otp(sms_auth_id)

      expect(WebMock).to have_requested(:patch, "https://api.xkepster.com/sms_auths/#{sms_auth_id}/resend_otp")
        .with(body: hash_including(
          "data" => hash_including(
            "type" => "sms_auths",
            "id" => sms_auth_id
          )
        ))
    end

    context "with machine token" do
      let(:machine_token) { "machine-token-123" }
      let(:machine_client) { Xkepster::Client.new(api_key: api_key, base_url: "https://api.xkepster.com", machine_token: machine_token) }
      let(:machine_sms_auth) { machine_client.sms_auth }

      before do
        stub_request(:patch, "https://api.xkepster.com/sms_auths/#{sms_auth_id}/resend_otp")
          .with(headers: { "X-Machine-Token" => machine_token })
          .to_return(
            status: 200,
            body: {
              data: {
                type: "sms_auths",
                id: sms_auth_id,
                attributes: { status: "pending" }
              }
            }.to_json,
            headers: { "Content-Type" => "application/vnd.api+json" }
          )
      end

      it "includes X-Machine-Token header" do
        machine_sms_auth.resend_otp(sms_auth_id)

        expect(WebMock).to have_requested(:patch, "https://api.xkepster.com/sms_auths/#{sms_auth_id}/resend_otp")
          .with(headers: { "X-Machine-Token" => machine_token })
      end
    end
  end
end

