# frozen_string_literal: true

module Xkepster
  module Resources
    class Sessions < Base
      def list(opts = {})
        filter = opts.fetch(:filter, {})
        params = {}
        filter.each do |key, value|
          params["filter[#{key}]"] = value
        end

        client.get("sessions", params: params)
      end

      def create(client, user_id, attrs = {})
        relationships = {
          "user" => {
            "data" => { "type" => "users", "id" => user_id }
          }
        }
        payload = build_json_api_payload("sessions", nil, attrs, relationships)
        client.post("sessions", body: payload)
      end

      def retrieve(session_id, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs({}, :sessions, fields: fields, field_inputs: field_inputs)
        client.get("sessions/#{session_id}", params: params)
      end

      def get(session_id)
        client.get("sessions/#{session_id}")
      end

      def revoke(session_id)
        payload = build_json_api_payload("sessions", session_id, { active: false })
        
        client.patch("sessions/#{session_id}", body: payload)
      end

      def update_activity(session_id)
        payload = build_json_api_payload("sessions", session_id, {})
        client.patch("sessions/#{session_id}", body: payload)
      end
    end
  end
end
