# frozen_string_literal: true

module Xkepster
  module Resources
    class SmsAuth < Base

      def list(opts = {})
        filter = opts.fetch(:filter, {})
        params = {}
        filter.each do |key, value|
          params["filter[#{key}]"] = value
        end
        client.get("sms_auths", params: params)
      end

      def delete(sms_auth_id)
        client.delete("sms_auths/#{sms_auth_id}")
      end

      def authenticate(phone_number:, group_id:)
        relationships = {
          group: { data: { type: "groups", id: group_id } }
        }

        payload = build_json_api_payload(
          "sms_auths",
          nil,
          { 
            phone_number: phone_number 
          },
          relationships
        )
        client.post("sms_auths/authenticate", body: payload)
      end

      def register(phone_number:, group_id:)
        relationships = {
          group: { data: { type: "groups", id: group_id } }
        }

        payload = build_json_api_payload(
          "sms_auths",
          nil,
          { 
            phone_number: phone_number 
          },
          relationships
        )
        client.post("sms_auths", body: payload)
      end

      def verify_otp(sms_auth_id:, otp:, claims: {}, user_params: nil)
        claims = user_params unless user_params.nil?

        attrs = { "otp" => otp }
        attrs["claims"] = claims unless claims.empty?

        payload = build_json_api_payload("sms_auths", sms_auth_id, attrs)
        client.patch("sms_auths/#{sms_auth_id}/verify_otp", body: payload)
      end

      def resend_otp(sms_auth_id)
        payload = build_json_api_payload("sms_auths", sms_auth_id)
        client.patch("sms_auths/#{sms_auth_id}/resend_otp", body: payload)
      end

    end
  end
end
