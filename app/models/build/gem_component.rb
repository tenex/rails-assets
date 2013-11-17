module Build

  class GemComponent < SimpleDelegator

    alias_method :bower_component, :__getobj__

    def filename
      "#{name}-#{version}.gem"
    end

    def name
      "#{GEM_PREFIX}#{short_name}"
    end

    def short_name
      bower_component.full_name.sub('/', '--')
    end

    def version
      Utils.fix_version_string(bower_component.version)
    end

    def dependencies
      Hash[bower_component.dependencies.map do |name, version|
        ["#{GEM_PREFIX}#{Utils.fix_gem_name(name, version)}", Utils.fix_version_string(version)]
      end]
    end

    def module
      name.gsub('.', '-').gsub('_', '-').split("-").map { |e| e.capitalize }.join('')
    end
  end
end
