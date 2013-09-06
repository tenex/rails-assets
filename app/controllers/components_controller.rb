class ComponentsController < ApplicationController
  def index
    respond_to do |format|
      format.html {}
      format.json do
        render(json: Component.all.map {|c| component_data(c) })
      end
    end
  end

  def create
    name, version = component_params[:name].to_s.strip, component_params[:version]

    component = if component = Component.where(name: name).first
      if version.blank?
        component
      else
        if component.versions.where(string: version).first
          component
        else
          build(name, version)
        end
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
      versions:     component.versions.map {|v| v.string },
      dependencies: component.versions.last.dependencies.to_a
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
