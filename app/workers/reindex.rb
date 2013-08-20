class Reindex
  include Sidekiq::Worker
  sidekiq_options :queue => :reindex

  def perform(force = false)
    index = Index.new

    if force || index.stale?
      puts "Generating index"
      index.with_lock do
        HackedIndexer.new(DATA_DIR).generate_index
        index.generated!
      end
    else
      puts "Index is fresh - skipping"
    end
  end
end
