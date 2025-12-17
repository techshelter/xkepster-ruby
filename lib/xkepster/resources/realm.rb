# frozen_string_literal: true

module Xkepster
  module Resources
    class Realm < Base
      def get
        client.get("realm")
      end
    end
  end
end
