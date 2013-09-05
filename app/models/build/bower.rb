module Build
  class Bower
    include Utils

    def initialize(build_dir)
      @build_dir = build_dir
    end

    def install(component)
      sh @build_dir, BOWER_BIN, "install", "-p", "-F", component.full, "--json"
    end
  end
end
