require "sidekiq"

Sidekiq.configure_server do |config|
  config.redis = { :namespace => Rails::Assets::REDIS_NAMESPACE }
end

Sidekiq.configure_client do |config|
  config.redis = { :namespace => Rails::Assets::REDIS_NAMESPACE }
end
