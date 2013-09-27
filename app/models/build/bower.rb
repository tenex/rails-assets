module Build
  class Bower
    extend Utils

    def self.install(component_name, build_dir)
      sh(
        build_dir, BOWER_BIN,
        "install", "-p", "-F", component_name, "--json"
      )
    end

    def self.info(component_name)
      JSON.parse sh(
        '/tmp', BOWER_BIN,
        "info", component_name, "--json --quiet"
      )
    end
  end
end
