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
      dir = @bower_component.name

      all_source_paths = Paths.
        from(@bower_dir).
        reject(:minified?)

      all_main_paths = Paths.
        new(@bower_component.main).
        map(:expand_path, @bower_dir).
        select(:exist?)

      main_paths = {
        javascripts: all_main_paths.select(:javascript?),
        stylesheets: all_main_paths.select(:stylesheet?)
      }

      source_dir = {
        javascripts: main_paths[:javascripts].common_prefix || Pathname.new(@bower_dir),
        stylesheets: main_paths[:stylesheets].common_prefix || Pathname.new(@bower_dir),
        images: Pathname.new(@bower_dir)
      }

      source_paths = {
        javascripts: all_source_paths.select(:javascript?) + main_paths[:javascripts],
        stylesheets: all_source_paths.select(:stylesheet?) + main_paths[:stylesheets],
        images: all_source_paths.select(:image?)
      }.each do |type, files|
        # Remove all files that are not descendants of source dir
        # For example we don't include js files if there are coffee ones
        files.select!(:descendant?, source_dir[type])
      end

      target_dir = {
        javascripts: File.join(@gem_dir, 'vendor', 'assets', 'javascripts', dir),
        stylesheets: File.join(@gem_dir, 'vendor', 'assets', 'stylesheets', dir),
        images: File.join(@gem_dir, 'vendor', 'assets', 'images', dir)
      }

      [:javascripts, :stylesheets, :images].each do |type|
        relative_paths = source_paths[type].map(:relative_path_from, source_dir[type])
        target_paths = relative_paths.map(:expand_path, target_dir[type])
        source_paths[type].zip(target_paths).map { |source, target| copy_file(source, target) }
      end

      # Generate javascript manifest
      manifest_javascripts = main_paths[:javascripts].map(:relative_path_from, source_dir[:javascripts])
      generate_manifest manifest_javascripts, 'javascripts', 'js' do |files|
        files.map do |file_name|
          "//= require #{File.join(dir, file_name)}"
        end.join("\n")
      end unless manifest_javascripts.empty?

      # Generate stylesheet manifest
      manifest_stylesheets = main_paths[:stylesheets].map(:relative_path_from, source_dir[:stylesheets])
      generate_manifest manifest_stylesheets, 'stylesheets', 'css' do |files|
        "/*\n" +
        files.map { |file_name|
          " *= require #{File.join(dir, file_name)}"
        }.join("\n") +
        "\n */"
      end unless manifest_stylesheets.empty?

      generate_gem_structure
      build_gem

      @gem_component.update(@component, @version)

      Component.transaction do
        @component.save!
        @version.save!
      end
    end

    def generate_manifest(main_files, manifest_directory, manifest_extension)
      manifest_filename = "#{@bower_component.name}.js"

      manifest_relative_path = File.join(
        "vendor", "assets", manifest_directory, manifest_filename
      )

      manifest_path = File.join(@gem_dir, manifest_relative_path)

      Rails.logger.info "Creating manifest file #{manifest_path}"

      File.open(manifest_path, "w") do |manifest_file|
        manifest_file.puts(yield(main_files))
      end

      @gem_component.files << manifest_relative_path.to_s

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

    def copy_file(source, target)
      Rails.logger.info "Copying #{source} to #{target}"

      target.dirname.mkpath
      FileUtils.cp(source, target)
      @gem_component.files << target.relative_path_from(
        Pathname.new(@gem_dir)).to_s
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


