# Rails env
ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'

ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)
ActiveRecord::Migration.maintain_test_schema!
Capybara.default_driver = Capybara.javascript_driver = :selenium
#need to include Capybara::Angular::DSL?

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.include Rails.application.routes.url_helpers, type: :feature
  config.after(:each, type: :feature) do
    if @example.exception && Support::ContinuousIntegration.upload_screenshot_on_failure?
      puts "Failure detected. Uploading screenshot..."
      Support::Capybara.upload_screenshot
    end
  end

  config.after(:each, type: :feature) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = 'spec/requests'
  config.default_cassette_options = { match_requests_on: [:method, :uri, :body] }
  config.filter_sensitive_data("ENV['STRIPE_SECRET_KEY']") { ENV['STRIPE_SECRET_KEY'] }
  config.hook_into :webmock
  config.ignore_localhost = true
  #Uncomment when new requests should be recorded into existing cassettes
  #config.default_cassette_options.merge!(record: :new_episodes)
end
