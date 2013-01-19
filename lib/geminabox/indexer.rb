
# This module addresses Geminabox issue
# https://github.com/cwninja/geminabox/issues/70
#
# The underlying problem is rubygems issue
# https://github.com/rubygems/rubygems/issues/232, fixed by
# https://github.com/rubygems/rubygems/pull/364
#
# This library (and its call) should be deleted once that pull request is resolved.

require 'geminabox'
require 'rubygems/indexer'

module Geminabox::Indexer
  def self.germane?
    gem_version = Gem::Version.new(Gem::VERSION)
    v1_8        = Gem::Version.new('1.8')
    v1_8_25     = Gem::Version.new('1.8.25')

    (gem_version >= v1_8) && (gem_version < v1_8_25)
  end

  def self.updated_gemspecs(indexer)
    specs_mtime = File.stat(indexer.dest_specs_index).mtime
    newest_mtime = Time.at 0

    updated_gems = indexer.gem_file_list.select do |gem|
      gem_mtime = File.stat(gem).mtime
      newest_mtime = gem_mtime if gem_mtime > newest_mtime
      gem_mtime >= specs_mtime
    end

    indexer.map_gems_to_specs updated_gems
  end

  def self.patch_rubygems_update_index_pre_1_8_25(indexer)
    if germane?
      specs = updated_gemspecs(indexer)

      unless specs.empty?
        Gem::Specification.dirs = []
        Gem::Specification.add_specs(*specs)
      end
    end
  end
end
