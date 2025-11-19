# frozen_string_literal: true

module Xkpester
  module Resources
    class Base
      attr_reader :client
      
      def initialize(client)
        @client = client
      end
    end
  end
end