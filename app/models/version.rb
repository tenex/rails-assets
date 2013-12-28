class Version < ActiveRecord::Base
  extend Build::Utils

  belongs_to :component

  validates :string, presence: true

  validates :string, uniqueness: { scope: :component_id }

  scope :indexed, lambda { where(:build_status => "indexed") }
  scope :builded, lambda { where(:build_status => ["builded", "indexed"]) }
  scope :pending_index, lambda { where(:build_status => "builded") }

  scope :processed, lambda {
    where(build_status: ["builded", "indexed", "failed"], rebuild: false)
  }

  scope :string, lambda { |string|
    where(:string => self.fix_version_string(string))
  }

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

  def failed?
    build_status == 'failed'
  end

  def needs_build?
    (build_status != 'builded' && build_status != 'indexed') || rebuild?
  end

  def gem_path
    Rails.root.join('public', 'gems', "#{GEM_PREFIX}#{component.name}-#{string}.gem")
  end
end
