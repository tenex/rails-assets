class MainController < ApplicationController
  before_action :redirect_to_https, :only => ["home"]

  def home
    if params[:debug]
      render :json => request.env.inspect and return
    end
  end

  def dependencies
    lock_name = "request-#{Digest::MD5.hexdigest(params[:gems].to_s)}.lock"

    Build::FileStore.with_lock(lock_name) do
      gem_names = params[:gems].to_s
        .split(",")
        .select {|e| e.start_with?(GEM_PREFIX) }
        .map { |e| e.gsub(GEM_PREFIX, "") }

      pool = Thread.pool(5)

      gem_names.each do |name|
        if Component.needs_build?(name)
          pool.process do
            begin
              Build::Converter.run!(name, "latest")
            rescue Exception => e
              Rails.logger.error(e)
              Rails.logger.error(e.backtrace)
              capture_exception(e)
            end
          end
        end
      end

      pool.shutdown

      gems = gem_names.flat_map do |name|

        component = Component.find_by(name: name)

        if component # && component.built?
          component.versions.built.map do |v|
            {
              name:         "#{GEM_PREFIX}#{name}",
              platform:     "ruby",
              number:       v.string,
              dependencies: v.dependencies || {}
            }
          end
        else
          []
        end
      end

      Rails.logger.info(params)
      Rails.logger.info(gems)

      params[:json] ? render(json: gems) : render(text: Marshal.dump(gems))
    end
  end

  private

  def redirect_to_https
    redirect_to :protocol => "https://" unless (request.ssl? || request.local?)
  end
end
