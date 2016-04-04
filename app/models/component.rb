# == Schema Information
#
# Table name: components
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  homepage      :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  bower_name    :string(255)
#  summary_cache :json
#
# Indexes
#
#  index_components_on_name  (name) UNIQUE
#

class Component < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true

  has_many :versions, dependent: :destroy, autosave: false, validate: false

  before_save :update_summary_cache
  after_touch -> { save }

  def full_name
    GEM_PREFIX + name
  end

  def self.get(name, version)
    if component = where(name: name).first
      if version.blank?
        [component]
      elsif the_version = component.versions.string(version).first
        [component, the_version]
      else
        [component, component.versions.build(string: version)]
      end
    else
      component = create(name: name)

      if version.blank?
        [component]
      else
        [component, component.versions.build(string: version)]
      end
    end
  end

  def self.needs_build?(name, version = nil)
    component = Component.includes(:versions).references(:versions)
                         .where(name: name).first

    if version.nil?
      component.blank? || component.versions.builded.count == 0
    else
      version_model = component.versions.find_by(version: version)
      version_model.blank? || version_model.needs_build?
    end
  end

  def built?
    versions.builded.count > 0
  end

  def rebuild!
    versions.update_all(rebuild: true)
    UpdateComponent.perform_async(bower_name)
  end

  def self.rebuild!
    Version.update_all(rebuild: true)
    UpdateScheduler.perform_async
  end

  protected

  # Whenever we change either an attribute of the Component
  # or build a new version of it, we have to rebuild this.
  def update_summary_cache
    self.summary_cache = build_summary_cache
  end

  def build_summary_cache
    slice(:name, :description, :homepage).tap do |c|
      c[:versions] = versions.pluck(:string)
    end
  end
end
