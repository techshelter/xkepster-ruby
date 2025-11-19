# frozen_string_literal: true

module Xkpester
  module Resources
    class Tokens < Base
      def list(params = {})
        client.get("/tokens", params: params)
      end

      def create(user_id:, expires_at: nil)
        payload = {
          data: {
            type: "tokens",
            attributes: {
              expires_at: expires_at
            }.compact,
            relationships: {
              user: { data: { type: "users", id: user_id } }
            }
          }
        }
        client.post("/tokens", body: payload)
      end

      def rotate(token_id)
        payload = {
          data: {
            type: "tokens",
            id: token_id,
            attributes: {}
          }
        }
        client.patch("/tokens/#{token_id}", body: payload)
      end

      def revoke(token_id)
        payload = {
          data: {
            type: "tokens",
            id: token_id,
            attributes: { revoked: true }
          }
        }
        client.patch("/tokens/#{token_id}", body: payload)
      end
    end
  end
end