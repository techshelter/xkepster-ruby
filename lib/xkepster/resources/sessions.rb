# frozen_string_literal: true

module Xkepster
  module Resources
    class Sessions < Base
      def create(user_id, attributes: {})
        relationships = {
          "user" => {
            "data" => { "type" => "users", "id" => user_id }
          }
        }
        payload = build_json_api_payload("sessions", nil, attributes, relationships)
        client.post("sessions", body: payload)
      end

      def list(opts = {}, fields: nil, field_inputs: nil)
        filter = opts.fetch(:filter, {})
        params = {}
        filter.each do |key, value|
          params["filter[#{key}]"] = value
        end
        params = add_fields_and_inputs(params, :sessions, fields: fields, field_inputs: field_inputs)
        client.get("sessions", params: params)
      end

      def retrieve(session_id, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs({}, :sessions, fields: fields, field_inputs: field_inputs)
        client.get("sessions/#{session_id}", params: params)
      end

      def get(session_id)
        client.get("sessions/#{session_id}")
      end

      def revoke(session_id)
        payload = build_json_api_payload("sessions", session_id, { "active" => false })
        client.patch("sessions/#{session_id}", body: payload)
      end

      def update_activity(session_id)
        payload = build_json_api_payload("sessions", session_id, {})
        client.patch("sessions/#{session_id}", body: payload)
      end
    end
  end
end
