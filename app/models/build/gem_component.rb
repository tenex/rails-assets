module Build
  class GemComponent
    include Utils

    attr_accessor :files, :name, :version, :filename

    def initialize(bower_component_or_attrs)
      if bower_component_or_attrs.is_a?(BowerComponent)
        @bower_component = bower_component_or_attrs
      else
        bower_component_or_attrs.each do |key, value|
          self.send(:"#{key}=", value)
        end
      end
      @files = []
    end

    def name
      @name ||= "#{GEM_PREFIX}#{@bower_component.full_name}"
    end

    def short_name
      @short_name ||= @bower_component.name
    end

    def version
      @version ||= fix_version_string(@bower_component.version)
    end

    def filename
      @filename ||= "#{name}-#{version}.gem"
    end

    def module
      @module ||= "#{GEM_PREFIX}#{@bower_component.name.gsub(/\./, "_")}".split("-").map {|e| e.capitalize}.join
    end

    def dependencies
      @dependencies ||= @bower_component.dependencies.map do |name, version|
        BowerComponent.new(name, version).gem
      end
    end

    def update(component, version)
      component.description = self.description
      component.homepage    = self.homepage
      version.string        = self.version
      version.dependencies  = self.dependencies.inject({}) {|h,g| h.merge(g.short_name => g.version) }
    end


    def method_missing(name, *args, &block)
      if @bower_component.respond_to?(name)
        @bower_component.send(name, *args, &block)
      else
        super
      end
    end
  end
end
