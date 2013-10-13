module Build
  class Convert
    def initialize(name, version = nil)
      @bower_component = BowerComponent.new(name, version)
    end

    def convert!(opts = {}, &block)
      Rails.logger.tagged("build") do
        @opts = opts

        if @opts[:debug]
          dir = "/tmp/build"
          FileUtils.rm_rf(dir)
          FileUtils.mkdir_p(dir)
          build_in_dir(dir, &block)
        else
          Dir.mktmpdir do |dir|
            build_in_dir(dir, &block)
          end
        end
      end
    end

    def try_convert(opts = {})
      convert!(opts)
    rescue Build::BuildError => ex
      Rails.logger.error ex.message
      nil
    end

    def file_store
      @file_store ||= FileStore.new
    end

    protected

    def build_in_dir(dir, &block)
      Rails.logger.debug "Building in #{dir}"

      file_store.with_lock(file_store.bower_lock) do
        Bower.install(@bower_component.full, dir)
      end

      results = Dir[File.join(dir, "bower_components", "*")].map do |file|
        name = File.basename(file)

        if name == @bower_component.name && @bower_component.github?
          name = @bower_component.github_name
        end

        GemBuilder.new(dir, name).build!(@opts)
      end

      results.each do |result|
        if result[:pkg]
          file_store.save(result[:gem_component], result[:pkg])
        end
      end

      Reindex.perform_async

      block.call(dir) if block

      results.find {|r| r[:bower_component].name == @bower_component.name }
    end
  end
end
