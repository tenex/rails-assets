class UpdateScheduler
  include Sidekiq::Worker

  sidekiq_options :queue => 'update_scheduler', unique: :all, retry: false

  def perform
    Component.select(:id, :bower_name).find_each do |component|
      UpdateComponent.perform_async(component.bower_name)
    end
  end
end

