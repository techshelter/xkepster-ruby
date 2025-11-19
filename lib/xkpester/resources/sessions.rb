# frozen_string_literal: true

module Xkpester
  module Resources
    class Sessions < Base
      def list(params = {})
        client.get("/sessions", params: params)
      end

      def create(user_id:, ip_address: nil, user_agent: nil, device_name: nil)
        payload = {
          data: {
            type: "sessions",
            attributes: {
              ip_address: ip_address,
              user_agent: user_agent,
              device_name: device_name
            }.compact,
            relationships: {
              user: { data: { type: "users", id: user_id } }
            }
          }
        }
        client.post("/sessions", body: payload)
      end

      def retrieve(session_id)
        client.get("/sessions/#{session_id}")
      end

      def revoke(session_id)
        payload = {
          data: {
            type: "sessions",
            id: session_id,
            attributes: { active: false }
          }
        }
        client.patch("/sessions/#{session_id}", body: payload)
      end

      def update_activity(session_id)
        payload = {
          data: {
            type: "sessions",
            id: session_id,
            attributes: {}
          }
        }
        client.patch("/sessions/#{session_id}", body: payload)
      end
    end
  end
end