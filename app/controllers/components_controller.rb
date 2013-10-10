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

    component = if params[:_force]
      build(name, version)
    elsif component = Component.where(name: name).first
      if component.versions.built.string(version).first
        component
      else
        build(name, version)
      end
    else
      build(name, version)
    end

    render json: component_data(component)
  rescue Build::BuildError => ex
    Raven.capture_exception(ex)

    render json: {
      message:  discover_error_cause(ex.opts[:log]) || ex.message,
      log:      ex.opts[:log]
    }, status: :unprocessable_entity
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

  def discover_error_cause(log)
    return unless log
    if data = (JSON.parse(log) rescue nil)
      if error = Array(data).select {|e| e["level"] == "error" }.first
        error["message"]
      end
    end
  end

  def build(name, version)
    result = Build::Convert.new(name, version).convert!(
      debug: params[:_debug],
      force: params[:_force]
    )
    result[:component]
  end

  def component_params
    params.require(:component).permit(:name, :version)
  end
end
