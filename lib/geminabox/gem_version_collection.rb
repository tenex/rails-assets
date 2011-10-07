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
    @gems.sort_by { |version| version.number }
  end

  def |(other)
    self.class.new(self.gems | other.gems)
  end
  
  def each(&block)
    @gems.sort_by { |gem| gem.name }.each(&block)
  end
  
  def grouped_by(attr)
    grouped = @gems.inject(hash_of_arrays) do |grouped, gem| 
      grouped[gem.send(attr)] << gem
      grouped
    end
    grouped.each(&Proc.new) if block_given?
    grouped
  end

  private
  def hash_of_arrays
    Hash.new { |h,k| h[k] = [] }
  end
end
