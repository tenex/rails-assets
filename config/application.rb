require File.expand_path('../boot', __FILE__)

require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

Bundler.require(:default, Rails.env)

require_relative '../app/workers/update_scheduler'

module RailsAssets
  class Application < Rails::Application
    config.exceptions_app = self.routes

    config.cache_store = :redis_store, ENV['REDIS_URL']

    Rails.configuration.x.hostname = 'rails-assets.tenex.tech'
  end
end
