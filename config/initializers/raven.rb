if ENV["RAVEN_DSN"]
  Raven.configure do |config|
    config.dsn = ENV["RAVEN_DSN"]
  end
end
