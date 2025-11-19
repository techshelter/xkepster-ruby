# frozen_string_literal: true

module Xkpester
  module Resources
    class Groups < Base
      def list(params = {})
        client.get("/groups", params: params)
      end

      def create(payload)
        client.post("/groups", body: payload)
      end

      def retrieve(group_id)
        client.get("/groups/#{group_id}")
      end

      def update(group_id, payload)
        client.patch("/groups/#{group_id}", body: payload)
      end

      def delete(group_id)
        client.delete("/groups/#{group_id}")
      end
    end
  end
end