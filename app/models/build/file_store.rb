module Build
  module FileStore extend self

    def with_lock(lock, &block)
      locks_dir = File.join(DATA_DIR, 'locks').to_s

      unless Dir.exist?(locks_dir)
        FileUtils.mkdir_p(File.join(DATA_DIR, 'locks').to_s)
      end

      File.open(File.join(DATA_DIR, "locks/#{lock.to_s}.lock"), "w+") do |f|
        f.flock(File::LOCK_EX)
        begin
          yield
        ensure
          f.flock(File::LOCK_UN)
        end
      end
    end

  end
end
