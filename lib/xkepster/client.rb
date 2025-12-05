# frozen_string_literal: true

module Xkepster
  class Client
    attr_reader :config

    def initialize(api_key: nil, base_url: nil, timeout: nil, open_timeout: nil, adapter: nil, logger: nil,
                   user_agent: nil, log_level: nil, logging_enabled: nil, machine_token: nil)
      @config = Xkepster.config.dup
      @config.api_key = api_key if api_key
      @config.base_url = base_url if base_url
      @config.timeout = timeout if timeout
      @config.open_timeout = open_timeout if open_timeout
      @config.adapter = adapter if adapter
      @config.logger = logger if logger
      @config.user_agent = user_agent if user_agent
      @config.log_level = log_level if log_level
      @config.logging_enabled = logging_enabled unless logging_enabled.nil?
      @config.machine_token = machine_token if machine_token
      @xkepster_logger = nil
    end

    def users
      @users ||= Resources::Users.new(self)
    end

    def groups
      @groups ||= Resources::Groups.new(self)
    end

    def sms_auth
      @sms_auth ||= Resources::SmsAuth.new(self)
    end

    def email_auth
      @email_auth ||= Resources::EmailAuth.new(self)
    end

    def sessions
      @sessions ||= Resources::Sessions.new(self)
    end

    def tokens
      @tokens ||= Resources::Tokens.new(self)
    end

    def operation_tokens
      @operation_tokens ||= Resources::OperationTokens.new(self)
    end

    def audit_logs
      @audit_logs ||= Resources::AuditLogs.new(self)
    end

    def realm
      @realm ||= Resources::Realm.new(self)
    end

    def inspect
      "#<Xkepster::Client:#{object_id} config=#{config.inspect}>"
    end

    def get(path, params: {}, headers: {})
      request(:get, path, params: params, headers: headers)
    end

    def post(path, body: {}, headers: {})
      request(:post, path, body: body, headers: headers)
    end

    def patch(path, body: {}, headers: {})
      request(:patch, path, body: body, headers: headers)
    end

    def delete(path, params: {}, headers: {})
      request(:delete, path, params: params, headers: headers)
    end

    def connection
      @connection ||= Faraday.new(url: config.base_url) do |f|
        f.request :json
        f.response :json, content_type: "application/json"
        f.options.timeout = config.timeout
        f.options.open_timeout = config.open_timeout
        f.adapter config.adapter
        f.response :logger, config.logger, headers: false, bodies: false if config.logger
      end
    end

    private

    def xkepster_logger
      @xkepster_logger ||= Xkepster::Logger.new(
        output: config.log_output,
        level: config.log_level,
        enabled: config.logging_enabled
      )
    end

    def request(method, path, body: nil, params: nil, headers: nil)
      ensure_api_key!
      start_time = Time.now

      xkepster_logger.log_request(method, path, params: params, body: body, headers: headers)

      response = connection.run_request(method, path, body,
                                        default_headers.merge(headers || {})) do |req|
        req.params.update(params) if params && !params.empty?
      end

      duration = Time.now - start_time
      xkepster_logger.log_response(method, path, status: response.status, body: response.body, duration: duration)

      handle_response(response)
    rescue Faraday::TimeoutError => e
      xkepster_logger.log_error(e, method: method, path: path)
      raise TimeoutError, e.message
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT, SocketError => e
      xkepster_logger.log_error(e, method: method, path: path)
      raise ConnectionError, e.message
    rescue Faraday::ConnectionFailed, Faraday::SSLError => e
      xkepster_logger.log_error(e, method: method, path: path)
      raise ConnectionError, e.message
    rescue Faraday::Error => e
      xkepster_logger.log_error(e, method: method, path: path)
      raise ConnectionError, e.message
    end

    def ensure_api_key!
      return if config.api_key && !config.api_key.to_s.strip.empty?

      raise AuthenticationError.new("API key is missing. Set XKEPSTER_API_KEY or configure Xkepster.config.api_key")
    end

    def default_headers
      headers = {
        "X-Kepster-Key" => config.api_key,
        "Content-Type" => "application/vnd.api+json",
        "Accept" => "application/vnd.api+json",
        "User-Agent" => config.user_agent
      }
      headers["X-Machine-Token"] = config.machine_token if config.machine_token
      headers
    end

    def handle_response(response)
      status = response.status
      body = response.body
      parsed = parse_body(body)

      case status
      when 200, 201
        parsed
      when 202, 204
        parsed.nil? ? {} : parsed
      when 400
        raise ValidationError.new(message_from(parsed), status: status, details: parsed)
      when 401, 403
        raise AuthenticationError.new(message_from(parsed), status: status, details: parsed)
      when 404
        raise NotFoundError.new(message_from(parsed), status: status, details: parsed)
      when 429
        raise RateLimitError.new(message_from(parsed), status: status, details: parsed)
      when 500..599
        raise ServerError.new(message_from(parsed), status: status, details: parsed)
      else
        raise ApiError.new(message_from(parsed), status: status, details: parsed)
      end
    end

    def parse_body(body)
      return nil if body.nil? || body == ""
      return body if body.is_a?(Hash) || body.is_a?(Array)

      JSON.parse(body)
    rescue JSON::ParserError => e
      raise ResponseParsingError, e.message
    end

    def message_from(parsed)
      return "Request failed" unless parsed.is_a?(Hash)

      parsed["message"] || parsed["error"] || "Request failed"
    end
  end
end
