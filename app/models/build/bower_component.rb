module Build
  class BowerComponent
    attr_reader :cache_dir, :data

    # cache_dir - Build::Path to which component has been installed
    # data - The component's Hash returned by `bower info` or similar
    def initialize(cache_dir, data)
      @cache_dir = Path.new(cache_dir)
      @data = data
    end

    def component_dir
      cache_dir.join('bower_components', name)
    end

    def name
      data['pkgMeta']['name']
    end

    def user
      data['endpoint']['source'].split('/')[0]
    end

    def repo
      data['endpoint']['source'].split('/')[1]
    end

    def version
      if data['pkgMeta']['version']
        data['pkgMeta']['version']
      else
        raise BuildError.new(
          "#{full_name} has no verions defined. " +
          "Please create an issue in component's repository."
        )
      end
    end

    def description
      data['pkgMeta']['description'] || ""
    end

    def repository
      data['pkgMeta']['_source']
    end

    def homepage
      data['pkgMeta']['homepage']
    end

    def dependencies
      data['pkgMeta']['dependencies'] || {}
    end

    def main
      if data['pkgMeta']['main']
        [data['pkgMeta']['main']].flatten.compact
      end
    end

    def github?
      data['endpoint']['source'].include?('/')
    end

    def full_name
      source = data['endpoint']['source']

      if source.match(/^[^\/]+(\/[^\/]+)?$/) 
        source
      elsif source =~ /github\.com\/([^\/]+\/[^\/]+)/
        $1 # TODO: get rid of it
      else
        raise BuildError.new("#{source} is not valid source for rails-assets")
      end
    end

    def full
      "#{data['endpoint']['source']}##{data['endpoint']['target']}"
    end

    def paths
      Paths.from(cache_dir).map(:relative_path_from, cache_dir)
    end

    def main_paths
      Paths.new(main).
        map(:expand_path, cache_dir).select(:exist?).
        map(:relative_path_from, cache_dir)
    end

    def gem
      @gem ||= GemComponent.new(self)
    end

    def needs_build?
      Component.where
    end

    def version_model
      if component = Component.where(name: gem.short_name).first
        version = if ver = component.versions.string(gem.version).first
          ver
        else
          component.versions.new(string: gem.version)
        end

        version.component = component
        version
      else
        component = Component.new(name: gem.short_name)
        version = component.versions.new(string: gem.version)
        version.component = component
        version
      end
    end
  end
end
