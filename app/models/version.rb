require 'rubygems/version'

class Version < ActiveRecord::Base
  extend Build::Utils

  belongs_to :component

  validates :string, presence: true

  validates :string, uniqueness: { scope: :component_id }

  scope :indexed, -> { where(build_status: 'indexed') }
  scope :builded, -> { where(build_status: %w(builded indexed)) }
  scope :pending_index, -> { where(build_status: 'builded') }

  scope :processed, lambda {
    where(build_status: %w(builded indexed), rebuild: false)
  }

  scope :string, lambda { |string|
    where(string: fix_version_string(string))
  }

  def gem_version
    @gem_version ||= Gem::Version.new(string)
  end

  after_destroy :remove_component

  def remove_component
    component.destroy if component.versions.count == 0
  end

  before_save :update_caches

  def update_caches
    self.position = gem_version.segments.to_a.map do |s|
      Integer === s ?
        ".#{s.to_s[0...14].rjust(14, '0')}" :
        "-#{s[0...14].ljust(14, '0')}"
    end.join('') + '.'

    self.prerelease = gem_version.prerelease?

    self
  end

  def self.update_caches
    find_each do |version|
      version.update_caches.save!
    end
  end

  def gem
    @gem ||= Build::GemComponent.new(name: "#{GEM_PREFIX}#{component.name}", version: string)
  end

  def string=(string)
    self[:string] = self.class.fix_version_string(string)
  end

  def indexed?
    build_status == 'indexed'
  end

  def builded?
    build_status == 'builded' || build_status == 'indexed'
  end

  def needs_build?
    (build_status != 'builded' && build_status != 'indexed') || rebuild?
  end

  def gem_path
    Pathname.new(Figaro.env.data_dir).join(
      'gems',
      "#{GEM_PREFIX}#{component.name}-#{string}.gem"
    )
  end

  def gemspec_path
    Pathname.new(Figaro.env.data_dir).join(
      'quick', 'Marshal.4.8',
      "#{GEM_PREFIX}#{component.name}-#{string}.gemspec.rz"
    )
  end

  def rebuild!
    update_attribute(:rebuild, true)
    BuildVersion.perform_async(component.bower_name, bower_version)
  end
end
