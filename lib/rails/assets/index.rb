require "redis"
require "rails/assets/reindex"

module Rails
  module Assets
    class Index
      def save(component)
        logger.debug "Storing gem #{component.name} #{component.version}"

        deps = component.gem_dependencies
        unless deps.empty?
          logger.debug "aargs: #{deps.to_a.flatten.inspect}"
          redis.hmset(key("gems", component.gem_name, component.version), *deps.to_a.flatten)
        end

        redis.sadd(key("gems", component.gem_name), component.version)
        redis.sadd(key("gems"), component.gem_name)

        changed!
        Reindex.perform_async
      end

      def changed!
        redis.set(key("index", "changed"), Time.now.to_f.to_s)
      end

      def generated!
        redis.set(key("index", "generated"), Time.now.to_f.to_s)
      end

      def with_lock(&block)
        if redis.setnx(key("index", "lock"), "#{Process.pid}-#{Thread.current.object_id}")
          begin
            block.call
          ensure
            redis.del(key("index", "lock"))
          end
        else
          raise ReindexInProgress
        end
      end

      def stale?
        changed = redis.get(key("index", "changed")).to_f
        generated = redis.get(key("index", "generated")).to_f
        generated < changed
      end

      def exists?(component)
        key = key("gems", component.gem_name)
        if component.version
          redis.sismember(key, component.version)
        else
          redis.exists(key)
        end
      end

      def versions(gem_name)
        redis.smembers(key("gems", gem_name))
      end

      def dependencies(name, version)
        redis.hgetall(key("gems", name, version))
      end

      def key(*args)
        ([REDIS_NAMESPACE] + args).join(":")
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      protected

      def redis
        @redis ||= Redis.new
      end
    end
  end
end
