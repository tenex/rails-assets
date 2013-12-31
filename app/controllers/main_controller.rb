class MainController < ApplicationController
  before_action :redirect_to_https, :only => ["home"]

  def home
    if params[:debug]
      render :json => request.env.inspect and return
    end
  end

  def dependencies
    if params[:gems].blank?
      params[:json] ? render(json: []) : render(text: Marshal.dump([]))
      return
    end

    gem_names = params[:gems].to_s
      .split(",")
      .select {|e| e.start_with?(GEM_PREFIX) }
      .map { |e| e.gsub(GEM_PREFIX, "") }

    pool = Thread.pool(5)

    gem_names.each do |name|
      if Component.needs_build?(name)
        pool.process do
          Build::Locking.with_lock("build-in-dependencies-#{name}") do
            begin
              Build::Converter.run!(name, "latest")
            rescue Exception => e
              Rails.logger.error(e)
              Rails.logger.error(e.backtrace)
              capture_exception(e)
            end

            UpdateComponent.perform_in(2.minutes, name)
          end
        end
      end
    end

    pool.shutdown

    # Blocking reindex
    Build::Converter.index!

    gems = Component.where(name: gem_names).to_a.flat_map do |component|
      component.versions.indexed.map do |v|
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

    params[:json] ? render(json: gems) : render(text: Marshal.dump(gems))
  end

  private

  def redirect_to_https
    redirect_to :protocol => "https://" unless (request.ssl? || request.local?)
  end
end
