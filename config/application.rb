require File.expand_path('../boot', __FILE__)

require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'

Bundler.require(:default, Rails.env)

require_relative '../app/workers/update_scheduler'

module RailsAssetsApp
  # Rails Assets Application
  class Application < Rails::Application
    config.cache_store = :redis_store, Figaro.env.redis_url
    config.x.hostname = 'rails-assets.org'
    config.x.inline_ng_templates = true
  end
end
