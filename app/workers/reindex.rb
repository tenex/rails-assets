class Reindex
  include Sidekiq::Worker

  sidekiq_options queue: 'reindex', unique: true, retry: 0

  def perform
    Build::Locking.with_lock(:gems) do
      Rails.logger.info "Performing full reindex..."
      HackedIndexer.new(DATA_DIR).generate_index
    end
  end
end
