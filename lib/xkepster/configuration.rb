# frozen_string_literal: true

module Xkepster
  class Configuration
    attr_accessor :api_key, :base_url, :timeout, :open_timeout, :adapter, :logger, :user_agent, :webhook_secret,
                  :log_level, :log_output, :logging_enabled

    def initialize
      @api_key = ENV["XKEPSTER_API_KEY"]
      @base_url = ENV["XKEPSTER_BASE_URL"] || "https://api.xkepster.com"
      @timeout = Integer(ENV.fetch("XKEPSTER_TIMEOUT", 30))
      @open_timeout = Integer(ENV.fetch("XKEPSTER_OPEN_TIMEOUT", 5))
      @adapter = Faraday.default_adapter
      @logger = nil
      @log_level = ENV.fetch("XKEPSTER_LOG_LEVEL", "info").to_sym
      @log_output = $stdout
      @logging_enabled = ENV.fetch("XKEPSTER_LOGGING_ENABLED", "false") == "true"
      @user_agent = "xkepster-ruby #{Xkepster::VERSION} Ruby #{RUBY_VERSION}"
      @webhook_secret = ENV["XKEPSTER_WEBHOOK_SECRET"]
    end

    def inspect
      "#<Xkepster::Configuration:#{object_id} " \
        "api_key=[REDACTED] " \
        "base_url=#{@base_url.inspect} " \
        "timeout=#{@timeout.inspect} " \
        "open_timeout=#{@open_timeout.inspect} " \
        "adapter=#{@adapter.inspect} " \
        "logger=#{@logger.inspect} " \
        "log_level=#{@log_level.inspect} " \
        "logging_enabled=#{@logging_enabled.inspect} " \
        "user_agent=#{@user_agent.inspect} " \
        "webhook_secret=[REDACTED]>"
    end
  end
end
