class MainController < ApplicationController
  before_action :redirect_to_https, :only => ["home"]

  def home
    if params[:debug]
      render :json => request.env.inspect and return
    end
  end

  def dependencies
    gem_names = params[:gems].to_s
      .split(",")
      .select {|e| e.start_with?(GEM_PREFIX) }
      .map { |e| e.gsub(GEM_PREFIX, "") }
    
    gems = gem_names.flat_map do |name|

      Build::Converter.run!(name) if Component.needs_build?(name)

      component = Component.where(name: name).first

      if component && component.built?
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

  private

  def redirect_to_https
    redirect_to :protocol => "https://" unless (request.ssl? || request.local?)
  end
end
