# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

# Serve built gems from the disk folder
use Rack::Static,
  root: Figaro.env.data_dir,
  urls: %w(robots.txt favicon.ico avatar.png),
  cache_control: 'public, max-age=31536000'

use Rack::StaticIfPresent,
  root: Figaro.env.data_dir,
  urls: %w(/gems /quick),
  cache_control: 'public, max-age=31536000'

run Rails.application
