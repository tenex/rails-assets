module RailsAssets
  class FileStore
    attr_reader :root, :log
    def initialize(log = Logger.new(STDOUT))
      @log = log
      @root = DATA_DIR

      prepare_data_folders
    end

    def save(component)
      dest = File.join(gems_root, component.gem_filename)
      log.info "Writing #{component.gem_name} to #{dest}"

      with_lock(gems_lock) do
        FileUtils.mv component.tmpfile, dest
      end

      component.tmpfile = nil
    end

    def delete(component)
      FileUtils.rm File.join(gems_root, component.gem_filename)
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
      File.join(root, "gems")
    end

    def gems_lock
      File.join(root, "gems.lock")
    end

    def bower_lock
      File.join(root, "bower.lock")
    end
  end
end
