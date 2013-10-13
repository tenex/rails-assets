class Version < ActiveRecord::Base
  extend Build::Utils

  belongs_to :component

  validates :string, presence: true

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
    build_status != 'success' && build_status != 'error'
  end
end
