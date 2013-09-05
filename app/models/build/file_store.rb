module Build
  class FileStore
    attr_reader :root, :log
    def initialize
      @root = DATA_DIR

      prepare_data_folders
    end

    def save(gem_component, pkg)
      dest = File.join(gems_root, gem_component.filename)
      Rails.logger.info "Writing #{gem_component.name} to #{dest}"

      with_lock(gems_lock) do
        FileUtils.mv pkg, dest
      end
    end

    def delete(gem_component)
      FileUtils.rm File.join(gems_root, gem_component.filename)
    end

    def with_lock(lock, &block)
      File.open(lock, "w") do |f|
        f.flock(File::LOCK_EX)
        f.write Process.pid
        block.call(f)
        f.flock(File::LOCK_UN)
      end
    end

    def prepare_data_folders
      FileUtils.mkdir_p(gems_root)
    end

    def gems_root
      @gems_root ||= File.join(root, "gems")
    end

    def gems_lock
      @gems_lock ||= File.join(root, "gems.lock")
    end

    def index_lock
      @gems_lock ||= File.join(root, "index.lock")
    end

    def bower_lock
      @bower_lock ||= File.join(root, "bower.lock")
    end
  end
end
