class Component < ActiveRecord::Base
  validates :name, presence: true

  has_many :versions, dependent: :destroy

  def self.get(name, version)
    if component = where(name: name).first
      if version = component.versions.string(version).first
        [component, version]
      else
        [component, component.versions.new(string: version)]
      end
    else
      component = new(name: name)
      [component, component.versions.new(string: version)]
    end
  end

  def needs_build?(name, version = nil)
    component = Component.where(name: name).first

    if version.nil?
      component.blank? || component.versions.built.count == 0
    else
      version_model = component.versions.where(version: version)
      version_model.blank? || version_model.needs_build?
    end
  end

  def built?
    versions.built.count > 0
  end
end
