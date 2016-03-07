module Build
  class GemComponent < SimpleDelegator
    alias bower_component __getobj__

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
      Utils.fix_dependencies(bower_component.dependencies)
    end

    def dependencies_modules
      dependencies.map(&:first).map do |name|
        self.class.name_to_module(name)
      end
    end

    def license?
      bower_component.license.present? && bower_component.license.is_a?(String)
    end

    def licenses?
      bower_component.license.present? &&
        bower_component.license.is_a?(Array)
    end

    def license
      bower_component.license.to_s[0...64]
    end

    def licenses
      bower_component.license.map(&:to_s).map { |s| s[0...64] }
    end

    def module
      self.class.name_to_module(name)
    end

    def self.name_to_module(name)
      name.tr('.', '-').tr('_', '-').split('-').map(&:capitalize).join('')
    end
  end
end
