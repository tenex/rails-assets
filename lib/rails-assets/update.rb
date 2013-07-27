module RailsAssets
  class Update
    include Sidekiq::Worker
    sidekiq_options :queue => :update

    def perform(pkg)
      Convert.new(Component.new(pkg)).convert!
    end
  end
end
