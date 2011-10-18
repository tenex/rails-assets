require 'geminabox/gem_version'

class Geminabox::GemVersionCollection
  include Enumerable

  attr_reader :gems

  def initialize(initial_gems=[])
    @gems = []
    initial_gems.each { |gemdef| self << gemdef }
  end

  def <<(version_or_def)
    version = if version_or_def.is_a?(Geminabox::GemVersion)
                version_or_def
              else
                Geminabox::GemVersion.new(*version_or_def)
              end

    @gems << version
    @gems.sort!
  end

  def |(other)
    self.class.new(self.gems | other.gems)
  end

  def each(&block)
    @gems.each(&block)
  end

  def by_name
    grouped = @gems.inject(hash_of_collections) do |grouped, gem|
      grouped[gem.name] << gem
      grouped
    end

    if block_given?
      grouped.each(&Proc.new)
    else
      grouped
    end
  end

  private
  def hash_of_collections
    Hash.new { |h,k| h[k] = self.class.new }
  end
end
