# frozen_string_literal: true

require "json"
require "faraday"

require_relative "xkpester/version"
require_relative "xkpester/configuration"
require_relative "xkpester/error"
require_relative "xkpester/client"

require_relative "xkpester/resources/base"
require_relative "xkpester/resources/users"
require_relative "xkpester/resources/groups"
require_relative "xkpester/resources/sms_auth"
require_relative "xkpester/resources/email_auth"
require_relative "xkpester/resources/sessions"
require_relative "xkpester/resources/tokens"
require_relative "xkpester/webhook"

module Xkpester
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