GEM_PREFIX = "rails-assets-"
BOWER_BIN = "bower"
GIT_BIN = "git"
RAKE_BIN = "rake"
BOWER_MANIFESTS = ["component.json", "package.json", "bower.json"]
REDIS_NAMESPACE = "rails-assets"
DATA_DIR = ENV["DATA_DIR"] || File.expand_path("../../../data", __FILE__)
