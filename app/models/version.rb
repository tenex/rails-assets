# == Schema Information
#
# Table name: versions
#
#  id            :integer          not null, primary key
#  component_id  :integer
#  string        :string
#  dependencies  :hstore
#  created_at    :datetime
#  updated_at    :datetime
#  build_status  :string
#  build_message :text
#  asset_paths   :text             default([]), is an Array
#  main_paths    :text             default([]), is an Array
#  rebuild       :boolean          default(FALSE)
#  bower_version :string
#  position      :string(1023)
#  prerelease    :boolean          default(FALSE)
#
# Indexes
#
#  index_versions_on_bower_version  (bower_version)
#  index_versions_on_build_status   (build_status)
#  index_versions_on_component_id   (component_id)
#  index_versions_on_position       (position)
#  index_versions_on_prerelease     (prerelease)
#  index_versions_on_rebuild        (rebuild)
#  index_versions_on_string         (string)
#
# Foreign Keys
#
#  fk_versions_component_id  (component_id => components.id)
#

require 'rubygems/version'

class Version < ActiveRecord::Base
  extend Build::Utils

  belongs_to :component, touch: true

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
    component.delete if component.versions.count == 0
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
