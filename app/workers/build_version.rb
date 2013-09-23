class BuildVersion
  include Sidekiq::Worker

  sidekiq_options queue: 'default', unique: true

  def perform(name, version)
    Rails.logger.info "Building #{name}##{version}..."
    Build::Convert.new(name, version).convert!
  end
end
