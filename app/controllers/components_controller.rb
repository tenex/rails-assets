class ComponentsController < ApplicationController
  caches_page :index

  def index
    respond_to do |format|
      format.json do
        render(json: ComponentHelper.generate_components_json)
      end
    end
  end

  def new
  end

  def rebuild
    component = Component.find_by!(name: params[:name])
    component.versions.update_all(rebuild: true)
    UpdateComponent.perform_async(component.bower_name)

    redirect_to status_path, notice: 'Component scheduled for rebuild. Check back in 10 minutes. Also remember to remove all versions of this gem from your machine first.'
  end

  def create
    name = component_params[:name]
    version = component_params[:version]
    name = Build::Utils.fix_gem_name(name, version).gsub('/', '--')

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
    paths = paths.reject { |f| f.match(/(?:app|vendor)\/assets\/javascripts\/[^\/]+\.js$/) }
    paths = paths.reject { |f| f.match(/(?:app|vendor)\/assets\/stylesheets\/[^\/]+\.scss$/) }

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
            component.versions
                     .where(string: Build::Utils.fix_version_string(version)).first
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
