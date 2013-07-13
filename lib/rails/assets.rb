$:.unshift(File.expand_path("../../", __FILE__))

require "rails/assets/config"
require "rails/assets/component"
require "rails/assets/utils"
require "rails/assets/builder"
require "rails/assets/convert"
require "rails/assets/file_store"
require "rails/assets/index"

require "rails/assets/sidekiq"
require "rails/assets/reindex"
require "rails/assets/update"
