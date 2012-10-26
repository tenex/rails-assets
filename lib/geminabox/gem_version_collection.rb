require 'geminabox/gem_version'

# This class represents a sorted collection of Geminabox::GemVersion objects.
# It it used widely throughout the system for displaying and filtering gems.
class Geminabox::GemVersionCollection
  include Enumerable

  # Array of Geminabox::GemVersion objects, or an array of [name, version,
  # platform] triples.
  def initialize(initial_gems=[])
    @gems = initial_gems.map{|object|
      coerce_to_gem_version(object)
    }.sort
  end

  # FIXME: Terminology makes no sense when the version are not all of the same
  # name
  def oldest
    @gems.first
  end

  # FIXME: Terminology makes no sense when the version are not all of the same
  # name
  def newest
    @gems.last
  end

  def size
    @gems.size
  end

  def each(&block)
    @gems.each(&block)
  end

  # The collection can contain gems of different names, this method groups them
  # by name, and then sorts the different version of each name by version and
  # platform.
  #
  # yields 'foo_gem', version_collection
  def by_name(&block)
    @grouped ||= @gems.group_by(&:name).map{|name, collection|
      [name, Geminabox::GemVersionCollection.new(collection)]
    }.sort_by{|name, collection|
      name.downcase
    }

    if block_given?
      @grouped.each(&block)
    else
      @grouped
    end
  end

private
  def coerce_to_gem_version(object)
    if object.is_a?(Geminabox::GemVersion)
      object
    else
      Geminabox::GemVersion.new(*object)
    end
  end
end
