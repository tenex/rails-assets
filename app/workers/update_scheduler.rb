class UpdateScheduler
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options :queue => 'update_scheduler'

  recurrence { hourly }

  def perform
    Component.select(:name).find_each do |component|
      UpdateComponent.perform_async(component.name)
    end
  end
end
