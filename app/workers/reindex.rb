require 'rubygems/indexer'

# Generates specs.4.8 and latest_specs.4.8
class Reindex
  include Sidekiq::Worker

  # A reindex operation has no parameters; it simply reindexes everything
  # therefore only one should exist at a time and they need not be retried
  sidekiq_options queue: 'reindex', unique: :all, retry: 0

  def perform(_force = false)
    return unless Version.pending_index.present?
    Build::Locking.with_lock(:index) do
      Version.transaction do
        Version.pending_index.update_all(build_status: 'indexed')
        generate_indexes
      end
    end
    # Clear cache for components.json api endpoint
    PageCacheManager.new.expire_page(controller: :components,
                                     action: :index, format: :json)
    true
  end

  def generate_indexes
    write_index File.join(Figaro.env.data_dir, 'specs.4.8') do
      Version
        .builded
        .joins(:component)
        .order('components.name, versions.position')
        .where(prerelease: false)
        .pluck('components.name', 'string')
    end

    write_index File.join(Figaro.env.data_dir, 'latest_specs.4.8') do
      Version
        .builded
        .from("(#{Version.select('distinct on (component_id) *')
          .where(prerelease: false)
          .order('component_id, position desc').to_sql}) as versions")
        .joins(:component).order('components.name')
        .pluck('components.name', 'string').to_a
    end

    write_index File.join(Figaro.env.data_dir, 'prerelease_specs.4.8') do
      Version
        .builded
        .joins(:component)
        .order('components.name, versions.position')
        .where(prerelease: true)
        .pluck('components.name', 'string')
    end

    generate_compact_indexes
  end

  # Compact Indexes
  # References:
  # * https://github.com/bundler/compact_index
  # * http://andre.arko.net/2014/03/28/the-new-rubygems-index-format/
  # File.join(Figaro.env.data_dir, 'names')
  def generate_compact_indexes
    generate_compact_names
    generate_compact_info
    generate_compact_versions
  end

  def generate_compact_names
  end

  def generate_compact_info
  end

  def generate_compact_versions
  end


  def reindex_spec(name)
    puts "Generating gemspec.rz for #{name}..."

    gem_path = File.join(
      Figaro.env.data_dir, 'gems', name + '.gem'
    )

    gemspec_path = File.join(
      Figaro.env.data_dir,
      'quick', 'Marshal.4.8', name + '.gemspec.rz'
    )

    FileUtils.mkdir_p(File.dirname(gemspec_path))
    gemspec = gemspec_rz(read_spec(gem_path))
    open gemspec_path, 'wb' do |io| io.write(gemspec) end
  end

  def read_spec(path)
    Build::GemPackage.open File.open(path), 'r', nil do |pkg|
      return pkg.metadata
    end
  end

  def gemspec_rz(spec)
    self.class.indexer.abbreviate spec
    self.class.indexer.sanitize spec
    Gem.deflate(Marshal.dump(spec))
  end

  def write_index(path)
    data = yield

    data.each do |d|
      d[0] = "#{GEM_PREFIX}#{d[0]}"
      d << 'ruby'
    end

    minimized = minimize_specs(data)
    stringified = stringify(minimized)
    gunzipped = gunzip(stringified)

    open path, 'wb' do |io| io.write(stringified) end
    open "#{path}.gz", 'wb' do |io| io.write(gunzipped) end

    true
  end

  def minimize_specs(data)
    names     = Hash.new { |h, k| h[k] = k }
    versions  = Hash.new { |h, k| h[k] = Gem::Version.new(k) }
    platforms = Hash.new { |h, k| h[k] = k }

    data.each do |row|
      row[0] = names[row[0]]
      row[1] = versions[row[1].strip]
      row[2] = platforms[row[2]]
    end

    data
  end

  def stringify(value)
    Marshal.dump(value)
  end

  def gunzip(value)
    final = StringIO.new
    gzip = Zlib::GzipWriter.new(final)
    gzip.write(value)
    gzip.close

    final.string
  end

  def self.indexer
    @indexer ||=
      begin
        indexer = Gem::Indexer.new(Figaro.env.data_dir,
                                   build_legacy: false)
        def indexer.say(_message) end
        indexer
      end
  end
end
