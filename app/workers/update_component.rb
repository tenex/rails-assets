class UpdateComponent
  include Sidekiq::Worker

  sidekiq_options queue: 'update_component', unique: true

  def perform(name)
    component = Component.where(name: name).first
    db_versions = component.versions.map(&:string)
    bower_versions = Build::Bower.info(name)["versions"] || []

    (bower_versions - db_versions).each do |version|
      BuildVersion.perform_async(name, version)
    end
  end
end
