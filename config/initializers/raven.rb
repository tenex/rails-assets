Raven.configure do |config|
  config.dsn = Figaro.env.raven_dsn
  config.environments = %w[ production ]
  config.current_environment = Rails.env
  config.tags = { environment: Rails.env }
  config.excluded_exceptions = ['Build::BuildError']
end
