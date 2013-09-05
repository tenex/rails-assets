class Component < ActiveRecord::Base
  validates :name, presence: true

  has_many :versions

  def self.get(name, version)
    if component = where(name: name).first
      if version = component.versions.where(string: version).first
        [component, version]
      else
        [component, component.versions.new(string: version)]
      end
    else
      component = new(name: name)
      [component, component.versions.new(string: version)]
    end
  end
end
