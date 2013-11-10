class Reindex
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options queue: 'reindex', unique: true, retry: 0

  recurrence { minutely(15) }

  def perform
    Build::FileStore.with_lock(:gems) do
      Rails.logger.info "Performing full reindex..."
      Build::HackedIndexer.new(DATA_DIR).generate_index
    end
  end
end
