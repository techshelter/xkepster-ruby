# frozen_string_literal: true

require_relative "lib/xkepster/version"

Gem::Specification.new do |spec|
  spec.name = "xkepster-ruby"
  spec.version = Xkepster::VERSION
  spec.authors = ["yanovitchsky"]
  spec.email = ["yannakoun@gmail.com"]

  spec.summary = "Ruby client for the Xkepster authentication platform"
  spec.description = "A Ruby client library for Xkepster, providing user management, authentication (SMS and email), session handling, and token management APIs."
  spec.homepage = "https://github.com/techshelter/xkepster-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.8"
  spec.add_dependency "json", "~> 2.6"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "rake", "~> 13.0"
end
