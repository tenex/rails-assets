class BuildVersion
  include Sidekiq::Worker

  sidekiq_options queue: 'default', unique: true, retry: 3, failures: :exhausted

  def perform(name, version)
    Rails.logger.info "Building #{name}##{version}..."
    Build::Converter.run!(name, version)
  end
end
