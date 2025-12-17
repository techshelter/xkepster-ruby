# frozen_string_literal: true

require "webmock/rspec"
require "xkepster"

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration and clear env vars before each test
  config.before(:each) do
    # Store original env vars
    @original_env = {
      "XKEPSTER_API_KEY" => ENV["XKEPSTER_API_KEY"],
      "XKEPSTER_WEBHOOK_SECRET" => ENV["XKEPSTER_WEBHOOK_SECRET"],
      "XKEPSTER_MACHINE_TOKEN" => ENV["XKEPSTER_MACHINE_TOKEN"],
      "XKEPSTER_BASE_URL" => ENV["XKEPSTER_BASE_URL"]
    }

    # Clear env vars for tests
    ENV.delete("XKEPSTER_API_KEY")
    ENV.delete("XKEPSTER_WEBHOOK_SECRET")
    ENV.delete("XKEPSTER_MACHINE_TOKEN")
    ENV.delete("XKEPSTER_BASE_URL")

    Xkepster.reset_configuration!
  end

  config.after(:each) do
    # Restore original env vars
    @original_env.each do |key, value|
      if value
        ENV[key] = value
      else
        ENV.delete(key)
      end
    end
  end
end
