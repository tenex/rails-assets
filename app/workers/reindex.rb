class Reindex
  include Sidekiq::Worker

  sidekiq_options queue: 'reindex', unique: true, retry: 0

  def perform
    Build::Locking.with_lock(:gems) do
      Rails.logger.info "Performing full reindex..."
      HackedIndexer.new(Figaro.env.data_dir).generate_index
    end
  end
end
