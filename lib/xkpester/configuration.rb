# frozen_string_literal: true

module Xkpester
  class Configuration
    attr_accessor :api_key, :base_url, :timeout, :open_timeout, :adapter, :logger, :user_agent, :webhook_secret

    def initialize
      @api_key       = ENV["XKEPSTER_API_KEY"]
      @base_url      = ENV["XKEPSTER_BASE_URL"] || "https://api.xkepster.com"
      @timeout       = Integer(ENV.fetch("XKEPSTER_TIMEOUT", 30))
      @open_timeout  = Integer(ENV.fetch("XKEPSTER_OPEN_TIMEOUT", 5))
      @adapter       = Faraday.default_adapter
      @logger        = nil
      @user_agent    = "xkpester-ruby #{Xkpester::VERSION} Ruby #{RUBY_VERSION}"
      @webhook_secret = ENV["XKEPSTER_WEBHOOK_SECRET"]
    end

    def inspect
      "#<Xkpester::Configuration:#{object_id} " \
        "api_key=[REDACTED] " \
        "base_url=#{@base_url.inspect} " \
        "timeout=#{@timeout.inspect} " \
        "open_timeout=#{@open_timeout.inspect} " \
        "adapter=#{@adapter.inspect} " \
        "logger=#{@logger.inspect} " \
        "user_agent=#{@user_agent.inspect} " \
        "webhook_secret=[REDACTED]>"
    end
  end
end