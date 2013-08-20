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
end
