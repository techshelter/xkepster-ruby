# frozen_string_literal: true

module Xkepster
  module Resources
    class Tokens < Base
      def list(params = {}, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs(params, :tokens, fields: fields, field_inputs: field_inputs)
        client.get("tokens", params: params)
      end

      def rotate(token_id)
        payload = {
          data: {
            type: "tokens",
            id: token_id,
            attributes: {}
          }
        }
        client.patch("tokens/#{token_id}", body: payload)
      end

      def revoke(token_id)
        payload = {
          data: {
            type: "tokens",
            id: token_id,
            attributes: { revoked: true }
          }
        }
        client.patch("tokens/#{token_id}", body: payload)
      end
    end
  end
end
