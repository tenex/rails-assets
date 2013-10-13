module Build
  class GemBuilder
    include Utils

    attr_reader :dir, :name, :bower_component, :gem_component
    def initialize(dir, name)
      @dir, @name = dir, name
      gem_name = @name

      if name.include?("/") # github
        @user, @name = name.split("/",2)
        gem_name = "#{@user}--#{@name}"
      end

      @bower_dir = File.join(dir, "bower_components", @name)
      @gem_dir = File.join(dir, "gems", gem_name)
      @gem_files = []
    end

    def github?
      !!@user
    end

    def build!(opts = {})
      Rails.logger.tagged(name) do
        @bower_component = BowerComponent.from_manifests(@bower_dir, name)
        if github?
          @bower_component.github!(@user)
        end

        Rails.logger.info "Bower component: #{@bower_component.inspect}"

        # @sheerun: Need to refactor this...
        @gem_component = @bower_component.gem
        @component, @version = @gem_component.get_component_and_version!

        if @version.string.blank?
          raise BuildError.new(
            "Component has no verions defined. " +
            "Please create an issue in component's repository."
          )
        end

        # Save metadata even if in case of failed build
        Component.transaction do
          @component.save!
          @version.save!
        end

        result = if @version.needs_build? || opts[:force]
          build
          { pkg: File.join(@gem_dir, "pkg", gem_component.filename) }
        elsif @version.build_status == 'error'
          raise BuildError.new(@version.build_message)
        else
          Rails.logger.info "Bower component #{@bower_component.name} #{@bower_component.version} already converted - skipping"
          {}
        end

        result.merge(
          component:        @component,
          version:          @version,
          gem_component:    @gem_component,
          bower_component:  @bower_component
        )
      end
    end

    def build 

      transformations = compute_transformations(
        @bower_component.name,
        Pathname.new(@bower_dir),
        Pathname.new(@gem_dir),
        Paths.new(@bower_component.main)
      )

      transformations.each do |source, target|
        target.dirname.mkpath

        if source.is_a?(Pathname)
          Rails.logger.info "Copying #{source} to #{target}"
          FileUtils.cp(source, target)
        else
          File.open(target, "w") do |file|
            file.write(source)
          end
        end
      end

      @gem_component.files = transformations.map(&:last).
        map { |path| path.relative_path_from Pathname.new(@gem_dir) }.map(&:to_s)

      generate_gem_structure
      build_gem

      Component.transaction do
        @version.build_status = 'success'

        @component.save!
        @version.save!
      end
    rescue BuildError => e
      Component.transaction do
        @version.build_status = 'error'
        @version.build_message = e.message

        @component.save!
        @version.save!
      end

      raise
    end

    # name - The String representing name of the component
    # bower_path - The Path under which bower component code resist
    # gem_path - The Path under which gem should be placed
    # all_main_paths - The Paths fetched from bower component manifest under main key
    #
    # Returns file transformations to be made
    #   each transform is in form [source_path, target_path] or [source, target_path]
    def compute_transformations(name, bower_path, gem_path, all_main_paths = Paths.new)
      all_source_paths = Paths.from(bower_path).reject(:minified?)
      all_main_paths = all_main_paths.map(:expand_path, bower_path).select(:exist?)

      [:javascripts, :stylesheets, :images].flat_map do |type|
        main_paths = all_main_paths.select(:member_of?, type)

        source_dir = main_paths.common_prefix || bower_path
        target_dir = gem_path.join('vendor', 'assets', type.to_s)

        source_paths = all_source_paths.select(:member_of?, type).
          select(:descendant?, source_dir) + main_paths

        relative_paths = source_paths.map(:relative_path_from, source_dir)
        target_paths = relative_paths.map(:expand_path, target_dir.join(name))

        manifest_transform =
          if generator = manifest_generators[type]
            manifest_paths = main_paths.map(:relative_path_from, source_dir)
            unless manifest_paths.empty?
              [
                generator[:processor].call(manifest_paths),
                target_dir.join("#{name}.#{generator[:extension]}")
              ]
            end
          end

        (source_paths.zip(target_paths) + [manifest_transform]).compact
      end
    end

    def manifest_generators
      @manifest_generators ||= {
        javascripts: {
          extension: 'js',
          processor: lambda { |files|
            files.map do |file_name|
              "//= require #{File.join(dir, file_name)}"
            end.join("\n")
          }
        },
        stylesheets: {
          extension: 'css',
          processor: lambda { |files|
            "/*\n" +
            files.map { |file_name|
              " *= require #{File.join(dir, file_name)}"
            }.join("\n") +
            "\n */"
          }
        }
      }
    end

    def generate_gem_file(file)
      source_path = File.join(templates_dir, file)
      file.gsub!("GEM", @bower_component.gem.name)
      erb = file.sub!(/\.erb$/, "")
      target_path = File.join(@gem_dir, file)

      FileUtils.mkdir_p File.dirname(target_path)
      FileUtils.cp source_path, target_path

      @gem_component.files << file

      if erb
        File.open(target_path, "w") do |f|
          erb = ERB.new(File.read(source_path))
          erb.filename = source_path
          f.write erb.result(binding)
        end
      end

      Rails.logger.info "Generated #{target_path}"
    end

    def generate_gem_structure
      generate_gem_file "lib/GEM/version.rb.erb"
      generate_gem_file "lib/GEM.rb.erb"
      generate_gem_file "Gemfile"
      generate_gem_file "Rakefile"
      generate_gem_file "README.md.erb"

      # This must be the last one so that is can have full gem_files list
      generate_gem_file "GEM.gemspec.erb"
    end

    def templates_dir
      File.expand_path("../templates", __FILE__).to_s
    end

    def build_gem
      sh @gem_dir, RAKE_BIN, "build"
    end
  end
end


