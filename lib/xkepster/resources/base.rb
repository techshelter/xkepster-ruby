# frozen_string_literal: true

module Xkepster
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      protected

      def add_fields_and_inputs(params, resource_type, fields: nil, field_inputs: nil)
        params = params.dup

        if fields
          if fields.is_a?(Array)
            params[:fields] = { resource_type => fields.join(",") }
          elsif fields.is_a?(String)
            params[:fields] = { resource_type => fields }
          elsif fields.is_a?(Hash)
            params[:fields] = fields
          end
        end

        params[:field_inputs] = field_inputs if field_inputs

        params
      end
    end
  end
end
