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
      transformations = Transformer.component_transformations(
        @bower_component, @bower_dir
      ) + generate_gem_structure

      Transformer.process_transformations!(
        transformations, @bower_dir, @gem_dir
      )

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

    def generate_gem_file(file)
      source_path = Path.new(File.join(templates_dir, file))
      file.gsub!("GEM", @bower_component.gem.name)
      use_erb = file.sub!(/\.erb$/, "")
      target_path = Path.new(file)

      Rails.logger.info "Generating #{target_path}"

      if use_erb
        erb = ERB.new(File.read(source_path.to_s))
        erb.filename = source_path.to_s
        [erb.result(binding), target_path]
      else
        [source_path, target_path]
      end
    end

    def generate_gem_structure
      [
        generate_gem_file("lib/GEM/version.rb.erb"),
        generate_gem_file("lib/GEM.rb.erb"),
        generate_gem_file("Gemfile"),
        generate_gem_file("Rakefile"),
        generate_gem_file("README.md.erb"),
        generate_gem_file("GEM.gemspec.erb")
      ]
    end

    def templates_dir
      File.expand_path("../templates", __FILE__).to_s
    end

    def build_gem
      sh @gem_dir, RAKE_BIN, "build"
    end
  end
end


