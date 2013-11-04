require "rubygems/indexer"

# +------+       +------+       +------+       +------+       +------+
# |`.    |`.     |\     |\      |      |      /|     /|     .'|    .'|
# |  `+--+---+   | +----+-+     +------+     +-+----+ |   +---+--+'  |
# |   |  |   |   | |    | |     |      |     | |    | |   |   |  |   |
# +---+--+   |   +-+----+ |     +------+     | +----+-+   |   +--+---+
#  `. |   `. |    \|     \|     |      |     |/     |/    | .'   | .'
#    `+------+     +------+     +------+     +------+     +------+'

module Build
  module Converter extend self
    # Public: Performs full processing of given component
    #
    # name - component name to process
    # version - component version to process
    #
    # Returns The Version, already persisted
    # Raises Build::BuildError on any
    def run!(name, version = nil)
      # TODO: should component be saved if some of the dependencies failed?
      Converter.process!(name, version) do |versions, paths|
        Converter.persist!(versions, paths)
      end
    end

    # Public: processes (converts and builds) given bower_components
    #
    # bower_components - component and its deps yielded from install! method
    # gems_dir - directory to which .gem files should be written
    #
    # Yields [Array of Version, Array of Path]
    #  - paths to builded .gem files to insert into index
    #  - versions to save with build_status set to success or error + message
    #    and asset_paths + main_paths filled; not yet persisted
    #
    #  All builded gem files are removed after block finishes
    #  Path for failed versions is nil!
    def process!(component_name, component_version = nil)
      Dir.mktmpdir do |gems_dir|
        arr = Converter.install!(component_name, component_version) do |components|
          components.map do |component|
            version = component.version_model

            next unless version.needs_build?
            
            gem_path = begin
              Converter.convert!(component) do |output_dir, asset_paths, main_paths|
                version.build_status = 'success'
                version.asset_paths = asset_paths.map(&:to_s)
                version.main_paths = main_paths.map(&:to_s)
                Converter.build!(component, output_dir, gems_dir)
              end
            rescue Build::BuildError => e
              version.build_status = 'error'
              version.build_message = e.message
              nil
            end

            [version, gem_path]
          end.compact
        end

        yield [arr.map(&:first), arr.map(&:last).compact]
      end
    end

    # Public: Persists versions and .gem files returned from convert! method
    #
    # versions - Array of Version returned from convert! method
    # gem_paths - Array of Path returned from convert! method
    def persist!(versions, gem_paths)
      Converter.index!(gem_paths, Path.new(DATA_DIR)) unless gem_paths.empty?
      Version.transaction { versions.each(&:save!) } unless versions.empty?
    end

    # Internal: Installs component to temporary directory and yields path to it.
    #
    # Later functions can use `bower cache list <name>` to show any dependency.
    #
    # Almost all actions in this method are mutable and executed in lock.
    #
    # component_name - bower component name to install.
    # component_version - component version to install (default: nil)
    #
    # Raises Build::BuildError if installation failed for some reason.
    # Yields Array of Bower::Component - list of installed components
    #   Components are destroyed on filesystem when yielded block finishes
    #   For each component a Version and Component is created in database.
    def install!(component_name, component_version = nil)
      Dir.mktmpdir do |cache_dir|
        bower_components = FileStore.with_lock(:bower) do
          result = Utils.bower(
            cache_dir,
            'install -F -p',
            "#{component_name}##{component_version || "latest"}"
          )

          result.values.map do |data|
            bower_component = BowerComponent.new(Path.new(cache_dir), data)
            bower_component.version_model.save!
            bower_component
          end
        end

        yield bower_components
      end
    end

    # Internal: Converts given bower_component in cache_dir to gem in output_dir
    #
    # bower_component - Build::BowerComponent returned from install! method
    #
    # Yields [Path, Array<Path>, Array<Path>] output_path, and assets paths relative
    #   to output_path: asset_paths and main_paths (paths to all assets and paths to main assets)
    #   output_dir is destroyed after yielded block finishes
    def convert!(bower_component)
      Dir.mktmpdir do |output_dir|
        output_dir = Path.new(output_dir)

        transformations = Transformer.component_transformations(bower_component)

        asset_paths = transformations[:all].values
        main_paths = transformations[:main].values

        Transformer.process_transformations!(
          transformations[:all].merge(generate_gem_structure(bower_component)),
          bower_component.component_dir, output_dir
        )
        
        yield [output_dir, asset_paths, main_paths]
      end
    end

    # Internal: Builds bower_component gem in output_dir
    #
    # bower_component - BowerComponent to build yielded from install!
    # output_dir - Path to builded gem yielded from build!
    #
    # Returns Path to builded .gem file, 
    def build!(bower_component, output_dir, gems_dir)
      Utils.sh(output_dir, RAKE_BIN, "build")
      pkg_path = output_dir.join('pkg', bower_component.gem.filename)
      gem_path = Path.new(gems_dir).join('gems', bower_component.gem.filename)

      FileUtils.mkdir_p(File.dirname(gem_path.to_s))
      FileUtils.mv(pkg_path.to_s, gem_path.to_s)

      unless File.exist?(gem_path.to_s)
        raise BuildError.new('Gem file generation failed for unknown reason') 
      end

      gem_path
    end

    # Public: Copies gems in lock and updates index
    #
    # gem_paths - Array of Build::Path returned from calls to build! method
    # data_dir - Directory where gems will be moved and index updated
    def index!(gem_paths, data_dir)
      FileStore.with_lock(:gems) do
        FileUtils.mkdir_p(data_dir.join('gems').to_s)
        gem_paths.each do |gem_path|
          destination = data_dir.join('gems', File.basename(gem_path))
          FileUtils.mv(gem_path.to_s, destination.to_s, :force => true)
          stdout = capture(:stdout) do
            begin
              HackedIndexer.new(data_dir.to_s).update_index
            rescue
              HackedIndexer.new(data_dir.to_s).generate_index
            end
          end

          Rails.logger.debug stdout
        end
      end
    end

    private

    def generate_gem_file(bower_component, file)
      source_path = Path.new(File.join(templates_dir, file))
      file.gsub!("GEM", bower_component.gem.name)
      use_erb = file.sub!(/\.erb$/, "")
      target_path = Path.new(file)

      if use_erb
        # Parameters for erb mean no safe mode + strip whitelines
        erb = ERB.new(File.read(source_path.to_s), nil, '<>')
        erb.filename = source_path.to_s
        [erb.result(bower_component.instance_eval { binding }), target_path]
      else
        [source_path, target_path]
      end
    end

    def generate_gem_structure(bower_component)
      Hash[[
        "lib/GEM/version.rb.erb",
        "lib/GEM.rb.erb",
        "Gemfile",
        "Rakefile",
        "README.md.erb",
        "GEM.gemspec.erb"
      ].map { |file| generate_gem_file(bower_component, file) }]
    end

    def templates_dir
      File.expand_path("../templates", __FILE__).to_s
    end
  end
end
