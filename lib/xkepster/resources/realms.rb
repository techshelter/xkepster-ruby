# frozen_string_literal: true

module Xkepster
  module Resources
    class Realms < Base
      def get(realm_id)
        client.get("realms/#{realm_id}")
      end

      def create(attrs)
        payload = build_json_api_payload("realms", nil, attrs)
        client.post("realms", body: payload)
      end

      def list(opts = {})
        limit  = opts.fetch(:limit, 25)
        offset = opts.fetch(:offset, 0)
        filter = opts.fetch(:filter, {})

        params = {
          "page[limit]" => limit,
          "page[offset]" => offset
        }

        filter.each do |key, value|
          params["filter[#{key}]"] = value
        end

        client.get("realms", params: params)
      end


      def update(realm_id, attrs)
        payload = build_json_api_payload("realms", realm_id, attrs)
        client.patch("realms/#{realm_id}", body: payload)
      end

      def delete(realm_id)
        client.delete("realms/#{realm_id}")
      end
    end
  end
end
