# frozen_string_literal: true

module Xkpester
  module Resources
    class Users < Base
      def list(params = {})
        client.get("/users", params: params)
      end

      def create(payload)
        client.post("/users", body: payload)
      end

      def retrieve(user_id)
        client.get("/users/#{user_id}")
      end

      def update(user_id, payload)
        client.patch("/users/#{user_id}", body: payload)
      end

      def delete(user_id)
        client.delete("/users/#{user_id}")
      end
    end
  end
end