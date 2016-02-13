# Rails env
ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'capybara/rails'
require 'capybara/rspec'

ActiveRecord::Migration.maintain_test_schema!
Capybara.default_driver = Capybara.javascript_driver = :webkit
#need to include Capybara::Angular::DSL?

Capybara::Webkit.configure do |config|
  config.allow_url('stripecdn.com')
  config.allow_url('stripe.com')
  config.allow_url('api.mixpanel.com')
  config.allow_url('fonts.googleapis.com')
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.include Rails.application.routes.url_helpers, type: :feature

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
