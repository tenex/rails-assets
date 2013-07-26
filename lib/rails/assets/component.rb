require "rubygems/package"

module Rails
  module Assets
    class Component
      attr_accessor :name, :version, :tmpfile

      def initialize(pkg_name, version = nil)
        if version
          @name, @version = pkg_name, version
        else
          if pkg_name.start_with?(GEM_PREFIX)
            @name = pkg_name.sub(/^#{GEM_PREFIX}/, "")
          else
            @name, @version = name_and_version(pkg_name)
          end
        end
      end

      def full
        version ? "#{name}##{version}" : name
      end

      def gem_name
        "#{GEM_PREFIX}#{name}"
      end

      def gem_spec
        @gem_spec ||= extract_gem_spec
      end

      def gem_path
        path = File.join(DATA_DIR, "gems", gem_filename)
        File.exists?(path) ? path : tmpfile
      end

      def gem_filename
        "#{gem_name}-#{version}.gem"
      end

      def gem_dependencies
        gem_spec.runtime_dependencies.inject({}) do |h,d|
          h.merge(d.name => d.requirement.to_s)
        end
      end

      def description
        gem_spec.description
      end

      def homepage
        gem_spec.homepage
      end

      def extract_gem_spec
        if Gem::Package.respond_to?(:open)
          File.open(gem_path, "rb") do |f|
            Gem::Package.open(f, "r", nil) do |pkg|
              return pkg.metadata
            end
          end
        else
          Gem::Package.new(gem_path).spec
        end
      end

      protected

      def name_and_version(pkg)
        n,v = pkg.split("#").map {|e| e.strip }
        [n, v == "" ? nil : v]
      end
    end
  end
end
