# frozen_string_literal: true

require "regent"
require 'vcr'
require 'langchain'

Langchain.logger.level = :WARN

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter out sensitive data like API keys
  config.filter_sensitive_data('<OPENAI_API_KEY>') { ENV['OPENAI_API_KEY'] }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each, :vcr) do |example|
    VCR.use_cassette(cassette, record: :new_episodes) { example.call }
  end
end
