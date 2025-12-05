# frozen_string_literal: true

module Xkepster
  module Resources
    class Users < Base
      def list(params = {}, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs(params, :users, fields: fields, field_inputs: field_inputs)
        client.get("users", params: params)
      end

      def create(first_name:, last_name:, phone_number: nil, email: nil, role: "user", custom_fields: {}, group_ids: [])
        payload = {
          data: {
            type: "users",
            attributes: {
              first_name: first_name,
              last_name: last_name,
              phone_number: phone_number,
              email: email,
              role: role,
              custom_fields: custom_fields
            }.compact
          }
        }

        # Add group relationships if provided
        if group_ids && !group_ids.empty?
          payload[:data][:relationships] = {
            groups: {
              data: group_ids.map { |id| { type: "groups", id: id } }
            }
          }
        end

        client.post("users", body: payload)
      end

      def retrieve(user_id, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs({}, :users, fields: fields, field_inputs: field_inputs)
        client.get("users/#{user_id}", params: params)
      end

      def update(user_id, first_name: nil, last_name: nil, role: nil, custom_fields: nil, group_ids: nil)
        attributes = {
          first_name: first_name,
          last_name: last_name,
          role: role,
          custom_fields: custom_fields
        }.compact

        payload = {
          data: {
            type: "users",
            id: user_id,
            attributes: attributes
          }
        }

        # Add group relationships if provided
        if group_ids
          payload[:data][:relationships] = {
            groups: {
              data: group_ids.map { |id| { type: "groups", id: id } }
            }
          }
        end

        client.patch("users/#{user_id}", body: payload)
      end

      def lock(user_id, reason:)
        payload = {
          data: {
            type: "users",
            id: user_id,
            attributes: {
              locked: true,
              locked_reason: reason
            }
          }
        }
        client.patch("users/#{user_id}", body: payload)
      end

      def unlock(user_id)
        payload = {
          data: {
            type: "users",
            id: user_id,
            attributes: {
              locked: false
            }
          }
        }
        client.patch("users/#{user_id}", body: payload)
      end

      def promote_to_admin(user_id)
        payload = {
          data: {
            type: "users",
            id: user_id,
            attributes: {
              role: "admin"
            }
          }
        }
        client.patch("users/#{user_id}", body: payload)
      end

      def delete(user_id)
        client.delete("users/#{user_id}")
      end
    end
  end
end
