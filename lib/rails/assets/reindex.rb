require "sidekiq"
require "rails/assets/index"
require "rubygems/indexer"

Sidekiq.configure_client do |config|
  config.redis = { :namespace => Rails::Assets::REDIS_NAMESPACE }
end

module Rails
  module Assets
    class ReindexInProgress < Exception; end

    class Reindex
      include Sidekiq::Worker
      sidekiq_options :queue => :reindex

      def perform
        index = Index.new

        if index.stale?
          index.with_lock do
            Gem::Indexer.new(DATA_DIR).generate_index
            index.generated!
          end
        end
      end
    end
  end
end
