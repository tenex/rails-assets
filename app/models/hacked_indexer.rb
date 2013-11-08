require "rubygems/indexer"

class HackedIndexer < Gem::Indexer
  def build_indicies
    # ----
    # Gem::Specification.dirs = []
    # Gem::Specification.add_specs(*map_gems_to_specs(gem_file_list))
    # ++++
    Gem::Specification.all = map_gems_to_specs(gem_file_list) # This line
    # ----

    build_marshal_gemspecs
    build_modern_indicies if @build_modern

    compress_indicies
  end

  def update_index
    make_temp_directories

    specs_mtime = File.stat(@dest_specs_index).mtime
    newest_mtime = Time.at 0

    updated_gems = gem_file_list.select do |gem|
      gem_mtime = File.stat(gem).mtime
      newest_mtime = gem_mtime if gem_mtime > newest_mtime
      gem_mtime >= specs_mtime
    end

    if updated_gems.empty? then
      say 'No new gems'
      terminate_interaction 0
    end

    specs = map_gems_to_specs updated_gems
    prerelease, released = specs.partition { |s| s.version.prerelease? }

    # ----
    # Gem::Specification.dirs = []
    # Gem::Specification.add_specs(*map_gems_to_specs(gem_file_list))
    # ++++
    Gem::Specification.all = map_gems_to_specs(gem_file_list) # This line
    # ----

    files = build_marshal_gemspecs

    Gem.time 'Updated indexes' do
      update_specs_index released, @dest_specs_index, @specs_index
      update_specs_index released, @dest_latest_specs_index, @latest_specs_index
      update_specs_index(prerelease,
                        @dest_prerelease_specs_index,
                        @prerelease_specs_index)
    end

    compress_indicies

    verbose = Gem.configuration.really_verbose

    say "Updating production dir #{@dest_directory}" if verbose

    files << @specs_index
    files << "#{@specs_index}.gz"
    files << @latest_specs_index
    files << "#{@latest_specs_index}.gz"
    files << @prerelease_specs_index
    files << "#{@prerelease_specs_index}.gz"

    files = files.map do |path|
      path.sub(/^#{Regexp.escape @directory}\/?/, '') # HACK?
    end

    files.each do |file|
      src_name = File.join @directory, file
      dst_name = File.join @dest_directory, file # REFACTOR: duped above

      FileUtils.mv src_name, dst_name, :verbose => verbose,
                  :force => true

      File.utime newest_mtime, newest_mtime, dst_name
    end
  end
end
