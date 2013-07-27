require 'rubygems'
require 'bundler/setup'

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))
require "rails-assets/web"

map '/assets' do
  run RailsAssets::Web.sprockets
end

map '/' do
  run RailsAssets::Web
end
