class UpdateMetadata
  include Sidekiq::Worker

  sidekiq_options queue: 'default', unique: :all, retry: 0

  def perform(version_id)
    version = Version.includes(:component).find(version_id)

    Dir.mktmpdir do |dir|
      result = Build::Utils.bower(
        dir, 'info',
        "#{version.component.bower_name}##{version.string || "latest"}"
      )

      version.update_attributes(
        :dependencies => Build::Utils.fix_dependencies(
          result['dependencies'] || {}
        )
      )
    end
  end
end
