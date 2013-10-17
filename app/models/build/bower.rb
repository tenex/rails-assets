module Build
  class Bower
    extend Utils

    def self.install(component_name, build_dir)
      Utils.bower(
        build_dir,
        'install -p -F', component_name
      )
    end

    def self.info(component_name)
      Utils.bower(
        '/tmp',
        'info', component_name
      )
    end
  end
end
