class Version < ActiveRecord::Base
  belongs_to :component

  validates :string, presence: true

  def gem
    @gem ||= Build::GemComponent.new(name: "#{GEM_PREFIX}#{component.name}", version: string)
  end
end
