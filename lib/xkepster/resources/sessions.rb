# frozen_string_literal: true

module Xkepster
  module Resources
    class Sessions < Base
      def list(params = {}, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs(params, :sessions, fields: fields, field_inputs: field_inputs)
        client.get("sessions", params: params)
      end

      def retrieve(session_id, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs({}, :sessions, fields: fields, field_inputs: field_inputs)
        client.get("sessions/#{session_id}", params: params)
      end

      def revoke(session_id)
        payload = {
          data: {
            type: "sessions",
            id: session_id,
            attributes: { active: false }
          }
        }
        client.patch("sessions/#{session_id}", body: payload)
      end

      def update_activity(session_id)
        payload = {
          data: {
            type: "sessions",
            id: session_id,
            attributes: {}
          }
        }
        client.patch("sessions/#{session_id}", body: payload)
      end
    end
  end
end
