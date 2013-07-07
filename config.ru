$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))
require "rails/assets"

run Rails::Assets
