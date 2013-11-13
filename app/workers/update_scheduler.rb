class UpdateScheduler
  include Sidekiq::Worker

  sidekiq_options :queue => 'update_scheduler'

  def perform
    Component.select(:bower_name).find_each do |component|
      UpdateComponent.perform_async(component.bower_name)
    end
  end
end

