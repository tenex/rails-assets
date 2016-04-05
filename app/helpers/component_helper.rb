# Component Helper
module ComponentHelper
  extend self

  def generate_components_json
    json_str = ActiveRecord::Base.connection.select_value(%{
      SELECT json_agg(c.summary_cache) AS component_summary
        FROM components c
       WHERE c.id IN (
         SELECT v.component_id
           FROM versions v
          WHERE v.build_status='indexed'
       )
    })
    JSON.parse(json_str || '[]')
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
