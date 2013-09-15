GEM_PREFIX = "rails-assets-"
BOWER_BIN = File.expand_path("../../../node_modules/.bin/bower", __FILE__)
GIT_BIN = "git"
RAKE_BIN = "rake"
REDIS_NAMESPACE = "rails-assets"
DATA_DIR = ENV["DATA_DIR"] || File.expand_path("../../../data", __FILE__)
