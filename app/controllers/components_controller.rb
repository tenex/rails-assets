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
    # Always force build
    name, version = component_params[:name], component_params[:version]


    version_model = Build::Converter.run!(name, version)
    
    component = Component.find_by(name: name)
    ver = if ver.present?
      component.versions.
        where(string: Build::Utils.fix_version_string(version)).first
    else
      component.versions.last
    end

    if ver.blank?
      render json: { message: 'Build failed for unknown reason' },
        status: :unprocessable_entity
    elsif ver.build_status == 'success'
      render json: component_data(component)
    else
      render json: { message: ver.build_message },
        status: :unprocessable_entity
    end
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
