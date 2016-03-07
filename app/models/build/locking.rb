module Build
  module Locking
    extend self

    # Create an exclusive lock and yield
    def with_lock(lock_name, options = {})
      build_mutex(lock_name, options).with_lock do
        yield
      end
    end

    private

    def build_mutex(lock_name, options = {})
      duration = options.fetch(:duration, 240)
      expire = options.fetch(:expire, 260)
      Redis::Mutex.new(lock_name, block: duration, expire: expire)
    end
  end
end
