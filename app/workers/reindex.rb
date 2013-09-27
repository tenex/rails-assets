class Reindex
  include Sidekiq::Worker
  sidekiq_options :queue => :reindex, :unique => true

  def perform
    file_store = Build::FileStore.new
    file_store.with_lock(file_store.index_lock) do
      Rails.logger.info "Generating index"
      HackedIndexer.new(DATA_DIR).generate_index
    end
  end
end
