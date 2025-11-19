# Xkpester Ruby Client

A Ruby client library for the [Xkepster authentication platform](https://github.com/techshelter/xkepster). Provides comprehensive user management, authentication (SMS and email), session handling, and token management APIs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'xkpester-ruby'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install xkpester-ruby

## Configuration

Configure the client globally:

```ruby
require 'xkpester'

Xkpester.configure do |config|
  config.api_key = ENV['XKEPSTER_API_KEY']  # Required: Your realm API key
  config.base_url = ENV['XKEPSTER_BASE_URL'] || 'https://your-xkepster-instance.com/api/json'
  config.timeout = 30
  config.open_timeout = 5
end
```

Or configure per-client:

```ruby
client = Xkpester::Client.new(
  api_key: 'your-api-key',
  base_url: 'https://your-instance.com/api/json'
)
```

## Usage

### Users

```ruby
client = Xkpester::Client.new

# List users
users = client.users.list

# Create a user
user_payload = {
  data: {
    type: "users",
    attributes: {
      first_name: "John",
      last_name: "Doe",
      role: "user",
      custom_fields: {
        department: "Engineering"
      }
    }
  }
}
user = client.users.create(user_payload)

# Get a user
user = client.users.retrieve("user-uuid")

# Update a user
update_payload = {
  data: {
    type: "users",
    id: "user-uuid",
    attributes: {
      first_name: "Jane"
    }
  }
}
client.users.update("user-uuid", update_payload)

# Delete a user
client.users.delete("user-uuid")
```

### Groups

```ruby
# List groups
groups = client.groups.list

# Create a group
group_payload = {
  data: {
    type: "groups",
    attributes: {
      name: "Engineering Team",
      description: "Engineering department members",
      auth_strategy: "both",  # "sms", "email", or "both"
      allow_registration: true
    }
  }
}
group = client.groups.create(group_payload)

# Get a group
group = client.groups.retrieve("group-uuid")

# Update a group
client.groups.update("group-uuid", update_payload)

# Delete a group
client.groups.delete("group-uuid")
```

### SMS Authentication

```ruby
# Register with SMS (start authentication process)
sms_auth = client.sms_auth.register(
  phone_number: "+1234567890",
  group_id: "group-uuid"
)

# Verify OTP and complete registration
result = client.sms_auth.verify_otp(
  sms_auth_id: sms_auth['data']['id'],
  otp: "123456",
  user_params: {
    first_name: "John",
    last_name: "Doe"
  }
)

# Extract tokens from the result
access_token = result['meta']['access_token']
refresh_token = result['meta']['refresh_token']

# Resend OTP if needed
client.sms_auth.resend_otp(sms_auth['data']['id'])
```

### Email Authentication

```ruby
# Register with email (start authentication process)
email_auth = client.email_auth.register(
  email: "user@example.com",
  group_id: "group-uuid"
)

# Verify magic link token and complete registration
result = client.email_auth.verify_token(
  email_auth_id: email_auth['data']['id'],
  token: "magic-link-token",
  user_params: {
    first_name: "Jane",
    last_name: "Smith"
  }
)

# Resend magic link if needed
client.email_auth.resend_magic_link(email_auth['data']['id'])
```

### Sessions

```ruby
# Create a session
session = client.sessions.create(
  user_id: "user-uuid",
  ip_address: "192.168.1.1",
  user_agent: "Mozilla/5.0...",
  device_name: "iPhone 14 Pro"
)

# List sessions
sessions = client.sessions.list

# Get a session
session = client.sessions.retrieve("session-uuid")

# Revoke a session
client.sessions.revoke("session-uuid")

# Update session activity
client.sessions.update_activity("session-uuid")
```

### Tokens

```ruby
# Create a token
token = client.tokens.create(
  user_id: "user-uuid",
  expires_at: "2025-12-19T14:30:00Z"
)

# List tokens
tokens = client.tokens.list

# Rotate a token
rotated = client.tokens.rotate("token-uuid")

# Revoke a token
client.tokens.revoke("token-uuid")
```

### Error Handling

The client provides specific exception types for different error scenarios:

```ruby
begin
  client.users.retrieve("non-existent-uuid")
rescue Xkpester::NotFoundError => e
  puts "User not found: #{e.message}"
  puts "HTTP status: #{e.status}"
rescue Xkpester::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Xkpester::ValidationError => e
  puts "Validation error: #{e.message}"
  puts "Details: #{e.details}"
rescue Xkpester::RateLimitError => e
  puts "Rate limited: #{e.message}"
rescue Xkpester::ServerError => e
  puts "Server error: #{e.message}"
rescue Xkpester::ConnectionError => e
  puts "Connection failed: #{e.message}"
rescue Xkpester::TimeoutError => e
  puts "Request timed out: #{e.message}"
rescue Xkpester::ResponseParsingError => e
  puts "Failed to parse response: #{e.message}"
rescue Xkpester::ApiError => e
  puts "API error: #{e.message}"
end
```

### Environment Variables

The client can be configured using environment variables:

- `XKEPSTER_API_KEY` - Your realm API key
- `XKEPSTER_BASE_URL` - Base URL for the Xkepster API (defaults to https://api.xkepster.com)
- `XKEPSTER_TIMEOUT` - Request timeout in seconds (default: 30)
- `XKEPSTER_OPEN_TIMEOUT` - Connection timeout in seconds (default: 5)

## JSON:API Format

This client follows the JSON:API specification used by Xkepster. All requests and responses use the standard JSON:API format with `data`, `attributes`, `relationships`, and `meta` fields.

### Example Request Format

```ruby
payload = {
  data: {
    type: "users",
    attributes: {
      first_name: "John",
      last_name: "Doe"
    },
    relationships: {
      groups: {
        data: [
          { type: "groups", id: "group-uuid-1" }
        ]
      }
    }
  }
}
```

### Example Response Format

```ruby
{
  "data" => {
    "type" => "users",
    "id" => "user-uuid",
    "attributes" => {
      "first_name" => "John",
      "last_name" => "Doe",
      "role" => "user",
      "inserted_at" => "2025-11-19T14:30:00Z",
      "updated_at" => "2025-11-19T14:30:00Z"
    }
  }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests.

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linting
bundle exec rubocop

# Build the gem
bundle exec rake build

# Install locally
bundle exec rake install
```

You can also run `bin/console` for an interactive prompt that will allow you to experiment:

```ruby
# In bin/console
Xkpester.configure { |c| c.api_key = "your-test-key" }
client = Xkpester::Client.new
# Try out the API...
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/techshelter/xkpester-ruby.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Run the test suite (`bundle exec rspec`)
5. Run the linter (`bundle exec rubocop`)
6. Commit your changes (`git commit -am 'Add some amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).