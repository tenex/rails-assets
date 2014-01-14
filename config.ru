# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

# Serve built gems from the disk folder
use Rack::Static,
  root: Figaro.env.data_dir,
  urls: %w(/rules /latest_specs.4.8 /latest_specs.4.8.gz
    /prerelease_specs.4.8 /prerelease_specs.4.8.gz /specs.4.8 /specs.4.8.gz),
  cache_control: 'public, max-age=0, must-revalidate'

use Rack::Static,
  root: Figaro.env.data_dir,
  urls: %w(/gems /quick),
  cache_control: 'public, max-age=31536000'

run Rails.application
