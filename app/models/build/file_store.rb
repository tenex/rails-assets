module Build
  module FileStore extend self

    def with_lock(lock, &block)
      locks_dir = File.join(DATA_DIR, 'locks').to_s
      lock_name = File.join(DATA_DIR, "locks/#{lock.to_s}.lock")

      unless Dir.exist?(locks_dir)
        FileUtils.mkdir_p(File.join(DATA_DIR, 'locks').to_s)
      end

      Filelock(lock_name, timeout: 60, &block)
    end

  end
end
