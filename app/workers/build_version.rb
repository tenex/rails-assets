class BuildVersion
  include Sidekiq::Worker

  sidekiq_options queue: 'default', unique: true, retry: 0

  def perform(bower_name, version)
    Rails.logger.info "Building #{bower_name}##{version}..."
    Build::Converter.run!(bower_name, version)
    ::UpdateComponent.perform_in(2.minutes, bower_name) if version == "latest"
  end
end
