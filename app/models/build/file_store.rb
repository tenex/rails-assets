module Build
  module FileStore extend self

    def with_lock(lock, &block)
      File.open(File.join(DATA_DIR, "#{lock.to_s}.lock"), "w") do |f|
        f.flock(File::LOCK_EX)
        f.write Process.pid
        result = block.call(f)
        f.flock(File::LOCK_UN)
        result
      end
    end

  end
end
