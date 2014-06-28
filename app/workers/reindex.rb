class Reindex
  include Sidekiq::Worker

  sidekiq_options queue: 'reindex', unique: true, retry: 0

  def perform(force = false)
    Build::Converter.index!(force)

    # Overwrite the components_json cache key
    Rails.cache.write('components_json') do
      ComponentHelper.generate_component_json
    end
  end
end
