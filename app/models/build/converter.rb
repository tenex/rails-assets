require 'rubygems/indexer'

# +------+       +------+       +------+       +------+       +------+
# |`.    |`.     |\     |\      |      |      /|     /|     .'|    .'|
# |  `+--+---+   | +----+-+     +------+     +-+----+ |   +---+--+'  |
# |   |  |   |   | |    | |     |      |     | |    | |   |   |  |   |
# +---+--+   |   +-+----+ |     +------+     | +----+-+   |   +--+---+
#  `. |   `. |    \|     \|     |      |     |/     |/    | .'   | .'
#    `+------+     +------+     +------+     +------+     +------+'

module Build
  module Converter
    extend self

    # Public: Performs full processing of given component
    #
    # name - component name to process
    # version - component version to process
    #
    # Returns The Version, already persisted
    # Raises Build::BuildError on any
    def run!(name, version = nil)
      lock_name = "build-converter-run-#{Utils.fix_gem_name(name, version).gsub('/', '--')}.#{version}"

      # Lock here prevents multiple builds on same requests at the same time
      Build::Locking.with_lock(lock_name) do
        Converter.process!(name, version) do |versions_paths|
          Converter.persist!(versions_paths)
          Reindex.perform_async

          versions_paths.first.first
        end
      end
    end

    # Public: processes (converts and builds) given bower_components
    #
    # bower_components - component and its deps yielded from install! method
    # gems_dir - directory to which .gem files should be written
    #
    # Yields [Array of Version, Array of Path]
    #  - paths to builded .gem files to insert into index
    #    (if path is nil, then component has been alredy built)
    #  - versions to save with build_status set to "builded"
    #  - build_message and asset_paths + main_paths filled
    #  - no version is yet persisted
    #
    #  All builded gem files are removed after block finishes
    #  Path for failed versions is nil!
    def process!(component_name, component_version = nil)
      component_name = component_name.sub('--', '/')

      Dir.mktmpdir do |gems_dir|
        results = Converter.install!(component_name, component_version) do |components|
          components.map do |component|
            version = component.version_model

            ::Rails.logger.info "Building #{component.name}##{version.string}..."

            gem_filepath = Converter.convert!(component) do |output_dir, asset_paths, main_paths|
              version.build_status = 'builded'
              version.asset_paths = asset_paths.map(&:to_s)
              version.main_paths = main_paths.map(&:to_s)
              Converter.build!(component, output_dir, gems_dir)
            end

            [version, gem_filepath]
          end.compact
        end

        yield results
      end
    end

    # Public: Persists versions and .gem files returned from convert! method
    #
    # versions - Array of Version returned from convert! method
    # gem_paths - Array of Path returned from convert! method
    def persist!(versions_paths)
      Build::Locking.with_lock(:persist) do
        Version.transaction do
          data_dir = Path.new(Figaro.env.data_dir)

          to_persist = versions_paths.select do |version, path|
            if (version.new_record? || version.rebuild?) && path.present?
              version.component.save!
              version.component_id = version.component.id
              version.rebuild = false
              version.save
            else
              false
            end
          end

          versions = to_persist.map(&:first)
          gem_paths = to_persist.map(&:last)

          unless gem_paths.empty?
            FileUtils.mkdir_p(data_dir.join('gems').to_s)

            gem_paths.each do |gem_path|
              destination = data_dir.join('gems', File.basename(gem_path))
              FileUtils.mv(gem_path.to_s, destination.to_s, force: true)
              Reindex.new.reindex_spec(File.basename(gem_path).gsub(/\.gem\z/, ''))
            end
          end
        end
      end
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
        result = Utils.bower(
          cache_dir,
          'install -p -F',
          "#{component_name}##{component_version || 'latest'}"
        )

        bower_components = result.values.map do |data|
          BowerComponent.new(Path.new(cache_dir), data)
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

        asset_paths = transformations[:all].map(&:last)
        main_paths = transformations[:main].map(&:last)

        raise BuildError.new('No files to convert') if asset_paths.empty?

        Transformer.process_transformations!(
          transformations[:all].concat(generate_gem_structure(bower_component)),
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
    # Returns Path to builded .gem file
    def build!(bower_component, output_dir, gems_dir)
      Utils.sh(output_dir, RAKE_BIN, 'build')
      pkg_path = output_dir.join('pkg', bower_component.gem.filename)
      gem_path = Path.new(gems_dir).join('gems', bower_component.gem.filename)

      FileUtils.mkdir_p(File.dirname(gem_path.to_s))
      FileUtils.mv(pkg_path.to_s, gem_path.to_s)

      unless File.exist?(gem_path.to_s)
        raise BuildError.new('Gem file generation failed for unknown reason')
      end

      gem_path
    end

    # Public: Indexes all gems marked in database as built
    #
    # On success sets build_status of all such versions to "indexed"
    # If reindex failed, it:
    #   * removes .gem files from disk
    #   * sets status of such gem to "failed" and sets build_message
    def index!(force = false)
      Reindex.new.perform(force)
    end

    private

    def generate_gem_file(bower_component, file)
      source_path = Path.new(File.join(templates_dir, file))
      file.gsub!('GEM', bower_component.gem.name)
      use_erb = file.sub!(/\.erb$/, '')
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
      [
        'lib/GEM/version.rb.erb',
        'lib/GEM.rb.erb',
        'Gemfile.erb',
        'Rakefile',
        'README.md.erb',
        'GEM.gemspec.erb',
        'GEM.json.erb'
      ].map { |file| generate_gem_file(bower_component, file) }
    end

    def templates_dir
      File.expand_path('../templates', __FILE__).to_s
    end
  end
end
