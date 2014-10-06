class ComponentsController < ApplicationController
  def index
    respond_to do |format|
      format.html {}
      format.json do
        components = Rails.cache.fetch('components_json') do
          ComponentHelper.generate_components_json
        end

        render(json: components)
      end
    end
  end

  def new
  end

  def create
    name, version = component_params[:name], component_params[:version]
    name = Build::Utils.fix_gem_name(name, version).gsub('/', '--')

    component, ver = get_version(name, version)

    if ver.present? && ver.build_status == "failed"
      ver.destroy
    end

    Build::Converter.run!(name, version)

    component, ver = get_version(name, version)

    if ver.blank?
      render json: { message: 'Build failed for unknown reason' },
        status: :unprocessable_entity
    else
      render json: ComponentHelper.component_data(component)
    end
  rescue Build::BuildError => e
      render json: { message: e.message },
        status: :unprocessable_entity
  end

  def assets
    component = Component.find_by!(name: params[:name])
    version = component.versions.find_by!(string: params[:version])

    paths = version.asset_paths.map

    # TODO: exclude manifest assets from asset_paths at all...
    paths = paths.reject { |f| f.match(/(?:app|vendor)\/assets\/javascripts\/[^\/]+\.js/) }
    paths = paths.reject { |f| f.match(/(?:app|vendor)\/assets\/stylesheets\/[^\/]+\.css/) }

    paths = paths.map do |path|
      {
        path: path.match(/(?:app|vendor)\/assets\/[^\/]+\/(.+)/)[1],
        main: version.main_paths.include?(path),
        type: path[/javascript|stylesheet|image/]
      }
    end

    render json: paths
  end


  def get_version(name, version)

    component = Component.find_by(name: name)

    return unless component.present?

    ver = if version.present?
      component.versions.
        where(string: Build::Utils.fix_version_string(version)).first
    else
      component.versions.last
    end

    return unless ver.present?

    ver.reload

    [component, ver]
  end

  protected

  def component_params
    params.require(:component).permit(:name, :version)
  end
end
