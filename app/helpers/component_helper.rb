module ComponentHelper extend self
                       def generate_components_json
                         ids = Version.indexed.select(:component_id)
                                      .to_a.map(&:component_id)

                         Component.includes(:versions).references(:versions)
                                  .where(id: ids)
                                  .where("versions.build_status = 'indexed'")
                                  .select('components.*, versions.string')
                                  .to_a.map { |c| component_data(c) }
                       end

                       def component_data(component)
                         {
                           name:         component.name,
                           description:  component.description,
                           homepage:     component.homepage,
                           versions:     component.versions.map(&:string)
                         }
                       end
end
