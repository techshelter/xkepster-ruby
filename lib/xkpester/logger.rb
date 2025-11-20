# frozen_string_literal: true

require "logger"

module Xkpester
  class Logger
    LEVELS = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR,
      fatal: ::Logger::FATAL
    }.freeze

    attr_reader :logger, :enabled

    def initialize(output: $stdout, level: :info, enabled: true)
      @enabled = enabled
      @logger = ::Logger.new(output)
      @logger.level = LEVELS[level] || ::Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity} -- xkpester-ruby: #{msg}\n"
      end
    end

    def debug(message = nil, &block)
      return unless enabled

      @logger.debug(message, &block)
    end

    def info(message = nil, &block)
      return unless enabled

      @logger.info(message, &block)
    end

    def warn(message = nil, &block)
      return unless enabled

      @logger.warn(message, &block)
    end

    def error(message = nil, &block)
      return unless enabled

      @logger.error(message, &block)
    end

    def fatal(message = nil, &block)
      return unless enabled

      @logger.fatal(message, &block)
    end

    def log_request(method, path, params: nil, body: nil, headers: nil)
      return unless enabled

      info do
        message = "API Request: #{method.to_s.upcase} #{path}"
        message += " | Params: #{sanitize_data(params)}" if params && !params.empty?
        message += " | Body: #{sanitize_data(body)}" if body && !body.empty?
        message += " | Headers: #{sanitize_headers(headers)}" if headers && !headers.empty?
        message
      end
    end

    def log_response(method, path, status:, body: nil, duration: nil)
      return unless enabled

      level = response_log_level(status)
      public_send(level) do
        message = "API Response: #{method.to_s.upcase} #{path} | Status: #{status}"
        message += " | Duration: #{duration.round(3)}s" if duration
        message += " | Body: #{sanitize_data(body)}" unless body.nil? || body == ""
        message
      end
    end

    def log_error(error, method: nil, path: nil)
      return unless enabled

      error do
        message = "API Error: #{error.class} - #{error.message}"
        message += " | #{method.to_s.upcase} #{path}" if method && path
        message
      end
    end

    private

    def response_log_level(status)
      case status
      when 200..299
        :info
      when 300..399
        :warn
      when 400..499
        :warn
      when 500..599
        :error
      else
        :info
      end
    end

    def sanitize_data(data)
      return nil if data.nil?
      return data if data.is_a?(String)

      sanitized = deep_sanitize(data)
      sanitized.inspect
    end

    def sanitize_headers(headers)
      return nil if headers.nil?

      sanitized = headers.transform_values do |value|
        value.to_s.length > 20 ? "[REDACTED]" : value
      end
      sanitized.inspect
    end

    def deep_sanitize(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(key, value), result|
          result[key] = sensitive_key?(key) ? "[REDACTED]" : deep_sanitize(value)
        end
      when Array
        obj.map { |item| deep_sanitize(item) }
      else
        obj
      end
    end

    def sensitive_key?(key)
      key_str = key.to_s.downcase
      %w[password secret token api_key auth authorization credential].any? do |sensitive|
        key_str.include?(sensitive)
      end
    end
  end
end
