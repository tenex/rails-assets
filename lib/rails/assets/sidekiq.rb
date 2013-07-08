$:.unshift(File.expand_path("../../..", __FILE__))

require "sidekiq"
require "rails/assets/config"
require "rails/assets/reindex"

Sidekiq.configure_server do |config|
  config.redis = { :namespace => Rails::Assets::REDIS_NAMESPACE }
end
