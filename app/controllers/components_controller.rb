class ComponentsController < ApplicationController
  def index
    components = Component.includes(:versions).
      all.
      select { |c| c.versions.any? { |v| v.built? } }.
      map { |c| component_data(c) }

    respond_to do |format|
      format.html {}
      format.json do
        render(json: components)
      end
    end
  end

  def new
  end

  def create
    name, version = component_params[:name].to_s.strip, component_params[:version]

    Build::Converter.run!(name, version)

    component = Component.where(name: name).first
    component = nil if component.versions.built.string(version).first

    render json: component_data(component)
  rescue Build::BuildError => e
    Raven.capture_exception(e)
    render json: { message: e.message }, status: :unprocessable_entity
  end

  protected

  def component_data(component)
    {
      name:         component.name,
      description:  component.description,
      homepage:     component.homepage,
      versions:     component.versions.built.map {|v| v.string },
      dependencies: component.versions.built.last.dependencies.to_a
    }
  end

  def component_params
    params.require(:component).permit(:name, :version)
  end
end
