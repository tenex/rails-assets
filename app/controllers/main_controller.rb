class MainController < ApplicationController
  def home
    respond_to :html
  end

  def status
    @pending_index = Version.includes(:component).pending_index.load
    @pending_builds = Sidekiq::Queue
                      .new('default')
                      .map(&:as_json)
                      .map { |i| i['item']['args'] }
    @failed_jobs = FailedJob
                   .where('created_at > ?', 1.week.ago)
                   .order(:created_at)
  end

  def dependencies
    if params[:gems].blank?
      gems = []
    else
      gem_names = params[:gems].to_s.split(',')

      # TODO: Enable this in future. For now bundler sends all gems
      # instead only ones defined in source block.
      # invalid_gemfile = gem_names.find { |e| !e.start_with?(GEM_PREFIX) }.present?

      gem_names = gem_names.select { |e| e.start_with?(GEM_PREFIX) }
      gem_names = gem_names.map { |e| e.gsub(GEM_PREFIX, '') }

      # Ensure that dependencies we're about to send
      # can actually be retrieved from here
      gem_names.each do |name|
        next unless Component.needs_build?(name)
        begin
          ::BuildVersion.new.perform(name, 'latest')
          ::UpdateComponent.perform_async(name)
        rescue Build::BowerError => e
          raise e unless e.not_found?
          Rails.logger.info(
            "received dependency query for non-existent component [#{name}]"
          )
        rescue StandardError => e
          Rails.logger.error(e)
        end
      end

      Reindex.perform_async

      gems = Component.where(name: gem_names).to_a.flat_map do |component|
        component.versions.builded.map do |v|
          {
            name:         "#{GEM_PREFIX}#{component.name}",
            platform:     'ruby',
            number:       v.string,
            dependencies: v.dependencies || {}
          }
        end
      end

      Rails.logger.info(params)
      Rails.logger.info(gems)
    end

    respond_to do |format|
      format.all { render text: Marshal.dump(gems) }
      format.json { render json: gems }
    end
  end
end
