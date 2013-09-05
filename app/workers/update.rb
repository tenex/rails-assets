class Update
  include Sidekiq::Worker
  sidekiq_options :queue => :update

  def perform(name)
    Build::Convert.new(name).convert!(debug: true, force: true)
  end
end
