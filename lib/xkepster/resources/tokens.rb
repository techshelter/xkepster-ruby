# frozen_string_literal: true

module Xkepster
  module Resources
    class Tokens < Base
      def create(user_id, expires_at:, claims: {})
        relationships = {
          "user" => {
            "data" => { "type" => "users", "id" => user_id }
          }
        }

        attrs = { "expires_at" => coerce_expires_at(expires_at) }
        attrs["claims"] = claims unless claims.empty?

        payload = build_json_api_payload("tokens", nil, attrs, relationships)
        client.post("tokens", body: payload)
      end

      def list(params = {}, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs(params, :tokens, fields: fields, field_inputs: field_inputs)
        client.get("tokens", params: params)
      end

      def rotate(token_id)
        payload = build_json_api_payload("tokens", token_id, {})
        client.patch("tokens/#{token_id}", body: payload)
      end

      def revoke(token_id)
        payload = build_json_api_payload("tokens", token_id, { "revoked" => true })
        client.patch("tokens/#{token_id}", body: payload)
      end

      private

      def coerce_expires_at(expires_at)
        case expires_at
        when Time, DateTime
          expires_at.utc.iso8601
        when String
          expires_at
        else
          raise ArgumentError, "expires_at must be a Time, DateTime, or String"
        end
      end
    end
  end
end
