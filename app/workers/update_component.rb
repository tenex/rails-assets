class UpdateComponent
  include Sidekiq::Worker

  sidekiq_options queue: 'update_component', unique: true

  def perform(bower_name)

    versions = Build::FileStore.with_lock(:bower) do
      Build::Utils.bower('/tmp', 'info', bower_name)['versions'] || []
    end

    if component = Component.where(bower_name: bower_name).first
      versions = versions - component.versions.processed.map(&:string)
    end

    if versions.size > 0
      puts "Scheduling #{versions.size} versions of #{bower_name} for build..."
      versions.each do |version|
        BuildVersion.perform_async(bower_name, version)
      end
    end
  end
end
