module Rails
  module Assets
    GEM_PREFIX = "rails-assets-"
    BOWER_BIN = "bower"
    GIT_BIN = "git"
    RAKE_BIN = "rake"
    BOWER_MANIFESTS = ["bower.json", "package.json", "component.json"]
    REDIS_NAMESPACE = "rails-assets"
    DATA_DIR = ENV["DATA_DIR"] || File.expand_path("../../../../data", __FILE__)
  end
end
