class UpdateComponent
  include Sidekiq::Worker
  include Build::Utils

  sidekiq_options queue: 'update_component', unique: true

  def perform(name)
    versions = Build::Bower.info(name)["versions"] || []
    versions = versions.map { |version| fix_version_string(version) }

    if component = Component.where(name: name).first
      versions = versions - component.versions.processed.map(&:string)
    end

    if versions.size > 0
      puts "Scheduling #{versions.size} versions of #{name} for build..."
      versions.each do |version|
        BuildVersion.perform_async(name, version)
      end
    end
  end
end
