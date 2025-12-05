# frozen_string_literal: true

module Xkepster
  module Resources
    class AuditLogs < Base
      def list(params = {}, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs(params, :audit_logs, fields: fields, field_inputs: field_inputs)
        client.get("audit_logs", params: params)
      end

      def retrieve(audit_log_id, fields: nil, field_inputs: nil)
        params = add_fields_and_inputs({}, :audit_logs, fields: fields, field_inputs: field_inputs)
        client.get("audit_logs/#{audit_log_id}", params: params)
      end
    end
  end
end
