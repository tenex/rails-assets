class MainController < ApplicationController
  before_action :redirect_to_https, :only => ["home"]

  def home
    if params[:debug]
      render :json => request.env.inspect and return
    end
  end

  def status
    @new_components = Component.order(created_at: :desc).limit(10).to_a
    @pending_index = Version.includes(:component).pending_index.load
    @failed_builds = Version.includes(:component).failed.load
    @pending_builds = Sidekiq::Queue.new("default").map(&:as_json).map { |i| i["item"]["args"] }
    @failed_jobs = Sidekiq.redis { |c| c.lrange(:failed, 0, 50) }.map { |j| JSON.parse(j) }
  end

  def dependencies
    if params[:gems].blank?
      gems = []
    else
      gem_names = params[:gems].to_s
        .split(",")
        .select {|e| e.start_with?(GEM_PREFIX) }
        .map { |e| e.gsub(GEM_PREFIX, "") }

      gem_names.each do |name|
        if Component.needs_build?(name)
          ::UpdateComponent.perform_async(name)
        end
      end

      if Version.pending_index.count > 0
        Reindex.new.perform
      end

      gems = Component.where(name: gem_names).to_a.flat_map do |component|
        component.versions.builded.map do |v|
          {
            name:         "#{GEM_PREFIX}#{component.name}",
            platform:     "ruby",
            number:       v.string,
            dependencies: v.dependencies || {}
          }
        end
      end

      Rails.logger.info(params)
      Rails.logger.info(gems)
    end

    respond_to do |format|
      format.json { render json: gems }
      format.all { render text: Marshal.dump(gems) }
    end
  end

  def packages
    render :file => Rails.root.join('public', 'packages.json'),
      :layout => false
  end

  def package
    render json: {
      type: 'alias',
      url: indexed_packages[params[:name]]["url"]
    }
  end

  def indexed_packages
    @indexed_packages ||= JSON.parse(
      File.read(Rails.root.join('public', 'packages.json'))
    ).index_by { |p| p["name"] }
  end

  private

  def redirect_to_https
    redirect_to :protocol => "https://" unless (request.ssl? || request.local?)
  end
end
