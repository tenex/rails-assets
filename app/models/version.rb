class Version < ActiveRecord::Base
  extend Build::Utils

  belongs_to :component

  validates :string, presence: true

  validates :string, uniqueness: { scope: :component_id }

  scope :built, lambda { where(:build_status => "success") }

  scope :processed, lambda {
    where(:build_status => ["success", "error"])
  }

  scope :string, lambda { |string| where(:string => self.fix_version_string(string)) }

  def gem
    @gem ||= Build::GemComponent.new(name: "#{GEM_PREFIX}#{component.name}", version: string)
  end

  def string=(string)
    self[:string] = self.class.fix_version_string(string)
  end

  def built?
    build_status == 'success'
  end

  def needs_build?
    build_status != 'success' || rebuild?
  end

  def gem_path
    Rails.root.join('public', 'gems', "#{GEM_PREFIX}#{component.name}-#{string}.gem")
  end
end
