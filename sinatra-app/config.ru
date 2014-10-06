require 'rack/cache'
require 'sprockets'
require './application'

use Rack::Cache

map '/assets' do
  run Application.assets
end

run Application
