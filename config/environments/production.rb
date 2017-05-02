RailsAssetsApp::Application.configure do
  # Settings specified here will take precedence over those
  # in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true
  config.eager_load = true
  # Full error reports are disabled
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  # Cache files in the /srv/data directory, which is accessible via NFS by
  # both the build server (which must expire it) and the web server
  config.action_controller.page_cache_directory = '/srv/data'
  # config.action_dispatch.rack_cache = true

  config.serve_static_files = true

  config.static_cache_control = 'public, max-age=31536000'

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass
  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx
  # config.force_ssl = true
  # Set to :debug to see everything in the log.
  config.log_level = :info
  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store
  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # config.assets.precompile += %w( search.js )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found).
  config.i18n.fallbacks = true
  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify
  # config.autoflush_log = false
  config.log_formatter = ::Logger::Formatter.new
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    {
      params: event.payload[:params]
    }
  end
end
