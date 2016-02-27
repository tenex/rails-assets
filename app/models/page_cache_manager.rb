class PageCacheManager
  include ActionController::Caching::Pages
  include Rails.application.routes.url_helpers

  ACTION_CONTROLLER_METHODS = [:page_cache_directory, :perform_caching, :default_static_extension].freeze

  ACTION_CONTROLLER_METHODS.each do |method|
    define_singleton_method method do
      ActionController::Base.send(method)
    end
  end
end
