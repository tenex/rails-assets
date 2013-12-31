class UpdateComponent
  include Sidekiq::Worker

  sidekiq_options queue: 'update_component', unique: true

  def perform(bower_name)

    versions = Build::Utils.bower('/tmp', 'info', bower_name)['versions'] || []

    # Exclude prereleases
    versions = versions.reject { |v| v.match(/[a-z]/i) }

    if component = Component.find_by(bower_name: bower_name)
      versions = versions - component.versions.processed.map(&:bower_version)
    end

    if versions.size > 0
      puts "Scheduling #{versions.size} versions of #{bower_name} for build..."

      versions.each do |version|
        BuildVersion.perform_async(bower_name, version)
      end
    end
  end
end
