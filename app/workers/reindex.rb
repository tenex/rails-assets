class Reindex
  include Sidekiq::Worker

  sidekiq_options queue: 'reindex', unique: true, retry: 0

  def perform(force = false)
    Build::Converter.index!(force)
  end
end
