# frozen_string_literal: true

module Xkepster
  module Resources
    class SmsAuth < Base
      def register(phone_number:, group_id:)
        payload = {
          data: {
            type: "sms_auths",
            attributes: { phone_number: phone_number },
            relationships: {
              group: { data: { type: "groups", id: group_id } }
            }
          }
        }
        client.post("/sms_auths", body: payload)
      end

      def verify_otp(sms_auth_id:, otp:, user_params: {})
        payload = {
          data: {
            type: "sms_auths",
            id: sms_auth_id,
            attributes: {
              otp: otp,
              user_params: user_params
            }
          }
        }
        client.patch("/sms_auths/#{sms_auth_id}", body: payload)
      end

      def resend_otp(sms_auth_id)
        payload = {
          data: {
            type: "sms_auths",
            id: sms_auth_id,
            attributes: {}
          }
        }
        client.patch("/sms_auths/#{sms_auth_id}", body: payload)
      end
    end
  end
end