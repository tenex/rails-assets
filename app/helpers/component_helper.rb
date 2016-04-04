# Component Helper
module ComponentHelper
  extend self

  def generate_components_json
    Component
      .joins(:versions)
      .where(versions: { build_status: 'indexed' })
      .pluck(:summary_cache)
  end

  def component_data(component)
    {
      name:         component.name,
      description:  component.description,
      homepage:     component.homepage,
      versions:     component.versions.pluck(:string)
    }
  end
end
