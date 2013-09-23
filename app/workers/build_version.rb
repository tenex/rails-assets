class BuildVersion
  include Sidekiq::Worker

  sidekiq_options queue: 'default', unique: true

  def perform(name, version)
    puts "Building #{name}##{version}..."
    Build::Convert.new(name, version).convert!
  end
end
