class ComponentsController < ApplicationController
  def index
    ids = Version.indexed.select(:component_id).
      to_a.map(&:component_id)

    components = Component.includes(:versions).where(id: ids).
      to_a.map { |c| component_data(c) }

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
    name, version = component_params[:name], component_params[:version]

    name = Build::Utils.fix_gem_name(name, version).gsub('/', '--')

    Build::Converter.run!(name, version)
    
    component = Component.find_by(name: name)
    ver = if version.present?
      component.versions.
        where(string: Build::Utils.fix_version_string(version)).first
    else
      component.versions.last
    end

    Build::Converter.index!

    if ver.blank?
      render json: { message: 'Build failed for unknown reason' },
        status: :unprocessable_entity
    elsif ver.indexed?
      render json: component_data(component)
    else
      render json: { message: ver.build_message },
        status: :unprocessable_entity
    end
  end

  def assets
    component = Component.find_by!(name: params[:name])
    version = component.versions.find_by!(string: params[:version])

    main_paths = version.main_paths
    paths = version.asset_paths.map

    # TODO: exclude manifest assets from asset_paths at all...
    paths = paths.reject { |f| f.match(/vendor\/assets\/javascripts\/[^\/]+\.js/) }
    paths = paths.reject { |f| f.match(/vendor\/assets\/stylesheets\/[^\/]+\.css/) }
    
    paths = paths.map do |path|
      {
        path: path.match(/vendor\/assets\/[^\/]+\/(.+)/)[1],
        main: version.main_paths.include?(path),
        type: path[/javascript|stylesheet|image/]
      }
    end

    render json: paths
  end

  protected

  def component_data(component)
    {
      name:         component.name,
      description:  component.description,
      homepage:     component.homepage,
      versions:     component.versions.indexed.map {|v| v.string },
      dependencies: component.versions.indexed.last.dependencies.to_a
    }
  end

  def component_params
    params.require(:component).permit(:name, :version)
  end
end
