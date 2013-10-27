module Build
  module Convert # extends BowerComponent

    def convert!(options = {}, &block)
      Dir.mktmpdir do |dir|
        Rails.logger.debug "Building in #{dir}"

        file_store.with_lock(file_store.bower_lock) do
          Bower.install(self.full, dir)
        end

        results = Dir[File.join(dir, "bower_components", "*")].map do |file|
          name = File.basename(file)

          if name == self.name && self.github?
            name = self.github_name
          end

          GemBuilder.new(dir, name).build!(options)
        end

        results.each do |result|
          if result[:pkg]
            file_store.save(result[:gem_component], result[:pkg])
          end
        end

        Reindex.perform_async

        block.call(dir) if block

        results.find { |r| r[:bower_component].name == self.name }
      end
    end

    protected

    def file_store
      @file_store ||= FileStore.new
    end

  end
end
