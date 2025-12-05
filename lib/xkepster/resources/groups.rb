# frozen_string_literal: true

module Xkepster
  module Resources
    class Groups < Base
      def list(params = {}, fields: nil, field_inputs: nil)
        params = add_group_fields(params, fields)
        params = add_fields_and_inputs(params, :groups, fields: nil, field_inputs: field_inputs)
        client.get("groups", params: params)
      end

      def create(name:, description:, auth_strategy:, allow_registration:)
        payload = {
          data: {
            type: "groups",
            attributes: {
              name: name,
              description: description,
              auth_strategy: auth_strategy,
              allow_registration: allow_registration
            }
          }
        }
        client.post("groups", body: payload)
      end

      def retrieve(group_id, fields: nil, field_inputs: nil)
        params = {}
        params = add_group_fields(params, fields)
        params = add_fields_and_inputs(params, :groups, fields: nil, field_inputs: field_inputs)
        client.get("groups/#{group_id}", params: params)
      end

      def update(group_id, name: nil, description: nil, auth_strategy: nil, allow_registration: nil)
        attributes = {}
        attributes[:name] = name unless name.nil?
        attributes[:description] = description unless description.nil?
        attributes[:auth_strategy] = auth_strategy unless auth_strategy.nil?
        attributes[:allow_registration] = allow_registration unless allow_registration.nil?

        payload = {
          data: {
            type: "groups",
            id: group_id,
            attributes: attributes
          }
        }
        client.patch("groups/#{group_id}", body: payload)
      end

      def delete(group_id)
        client.delete("groups/#{group_id}")
      end

      private

      def add_group_fields(params, fields = nil)
        # Default fields to include all group attributes if not specified
        default_fields = %w[name description auth_strategy allow_registration]

        if fields.nil?
          # Use default fields if no fields specified
          params[:fields] = { groups: default_fields.join(",") }
        elsif fields.is_a?(Array)
          # Convert array to comma-separated string
          params[:fields] = { groups: fields.join(",") }
        elsif fields.is_a?(String)
          # Use string directly
          params[:fields] = { groups: fields }
        elsif fields == false
          # Don't add fields parameter if explicitly set to false
          # This allows for backward compatibility
        end

        params
      end
    end
  end
end
