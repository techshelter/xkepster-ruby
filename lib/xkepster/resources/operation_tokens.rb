# frozen_string_literal: true

module Xkepster
  module Resources
    class OperationTokens < Base
      def list(params = {}, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs(params, :operation_tokens, fields: fields, field_inputs: field_inputs)
        client.get("operation_tokens", params: params)
      end

      def create(purpose:, expires_at:, user_id:, metadata: {})
        payload = {
          data: {
            type: "operation_tokens",
            attributes: {
              purpose: purpose,
              expires_at: expires_at,
              metadata: metadata
            },
            relationships: {
              user: { data: { type: "users", id: user_id } }
            }
          }
        }
        client.post("operation_tokens", body: payload)
      end

      def verify_and_consume(operation_token_id:, token:, purpose:)
        payload = {
          data: {
            type: "operation_tokens",
            id: operation_token_id,
            attributes: {
              token: token,
              purpose: purpose
            }
          }
        }
        client.patch("operation_tokens/#{operation_token_id}", body: payload)
      end
    end
  end
end
