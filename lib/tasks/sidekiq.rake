namespace :sidekiq do
  desc "Schedule UpdateScheduler job"
  task :update => :environment do
    UpdateScheduler.perform_async
  end

  desc "Schedule Reindex job"
  task :reindex => :environment  do
    Reindex.perform_async
  end
end
