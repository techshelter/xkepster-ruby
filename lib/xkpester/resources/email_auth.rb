# frozen_string_literal: true

module Xkpester
  module Resources
    class EmailAuth < Base
      def register(email:, group_id:)
        payload = {
          data: {
            type: "email_auths",
            attributes: { email: email },
            relationships: {
              group: { data: { type: "groups", id: group_id } }
            }
          }
        }
        client.post("/email_auths", body: payload)
      end

      def verify_token(email_auth_id:, token:, user_params: {})
        payload = {
          data: {
            type: "email_auths",
            id: email_auth_id,
            attributes: {
              token: token,
              user_params: user_params
            }
          }
        }
        client.patch("/email_auths/#{email_auth_id}", body: payload)
      end

      def resend_magic_link(email_auth_id)
        payload = {
          data: {
            type: "email_auths",
            id: email_auth_id,
            attributes: {}
          }
        }
        client.patch("/email_auths/#{email_auth_id}", body: payload)
      end
    end
  end
end