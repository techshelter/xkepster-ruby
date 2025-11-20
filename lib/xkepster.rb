# frozen_string_literal: true

require "json"
require "faraday"

require_relative "xkepster/version"
require_relative "xkepster/configuration"
require_relative "xkepster/error"
require_relative "xkepster/logger"
require_relative "xkepster/client"

require_relative "xkepster/resources/base"
require_relative "xkepster/resources/users"
require_relative "xkepster/resources/groups"
require_relative "xkepster/resources/sms_auth"
require_relative "xkepster/resources/email_auth"
require_relative "xkepster/resources/sessions"
require_relative "xkepster/resources/tokens"
require_relative "xkepster/webhook"

module Xkepster
  class << self
    def configure
      yield(config)
      config
    end

    def config
      @config ||= Configuration.new
    end

    def reset_configuration!
      @config = Configuration.new
    end
  end
end