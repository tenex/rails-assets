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
      raise BuildError.new("Missing main file(s)") if @bower_component.main.blank?

      # Load files to extensions
      exts = extensions.map do |e|
        e.files = @bower_component.main.select do |file|
          e.matches?(file) && File.exist?(File.join(@bower_dir, file))
        end

        e
      end

      raise BuildError.new("Missing main file(s)") if exts.all? {|e| e.files.empty? }


      # Find additional files
      basedir = File.dirname(exts.map {|e| e.files }.flatten.first)
      exts.each do |e|
        if e.files.empty?
          e.files = find_files(basedir, e)
        end
      end


      # Remove min files
      exts.each do |ext|
        ext.files.reject! do |file|
          ext.exts.any? do |e|
            file.match(/min\.#{e}$/) && ext.files.include?(file.sub("min.", ""))
          end
        end
      end


      # Create assets files
      exts.each do |ext|
        FileUtils.mkdir_p File.join(@gem_dir, "vendor", "assets", ext.assets_dir)

        paths = ext.files.map do |file|
          path = File.join(@bower_component.name.to_s, file.sub(/^#{Regexp.escape(basedir)}/, ""))

          source = File.join(@bower_dir, file)
          target = File.join(@gem_dir, "vendor", "assets", ext.assets_dir, path)

          Rails.logger.info "Copying #{source} to #{target}"
          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.cp source, target
          @gem_component.files << File.join("vendor", "assets", ext.assets_dir, path)
          path
        end

        # Manifest file
        if ext.manifest_proc && !ext.files.empty?
          manifest_filename = "#{@bower_component.name}.#{ext.exts.first}"
          manifest_file = File.join(@gem_dir, "vendor", "assets", ext.assets_dir, manifest_filename)
          Rails.logger.info "Creating manifest file #{manifest_file}"
          File.open(manifest_file, "w") do |m|
            m.puts ext.manifest_proc.call(paths)
          end
          @gem_component.files << File.join("vendor", "assets", ext.assets_dir, manifest_filename)
        end
      end

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

    def find_files(basedir, ext)
      dir = File.join(@bower_dir, basedir)
      Rails.logger.debug "Looking for #{ext.exts} in #{dir}"
      Dir["#{dir}/**/*"].select {|f| ext.matches?(f) }
                        .map    {|f| File.join(basedir, f.sub(dir, "")) }
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
      File.expand_path("../templates", __FILE__)
    end

    def build_gem
      sh @gem_dir, RAKE_BIN, "build"
    end

    def extensions
      [
        Extension.new("javascripts", %w(js coffee)) do |files|
          files.map {|f| "//= require #{f}"}.join("\n")
        end,
        Extension.new("stylesheets", %w(css less scss sass)) do |files|
          "/*\n" + files.map {|f| " *= require #{f}"}.join("\n") + "\n */"
        end,
        Extension.new("images", %w(png gif jpg jpeg))
      ]
    end
  end
end


