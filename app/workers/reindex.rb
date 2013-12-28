class Reindex
  include Sidekiq::Worker

  sidekiq_options queue: 'reindex', unique: true, retry: 0

  def perform
    Build::Converter.index!
  end
end
