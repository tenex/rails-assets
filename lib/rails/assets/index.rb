require "redis"

module RailsAssets
  class Index
    def all
      redis.smembers(key("gems"))
    end

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

    def delete(component)
      redis.del(key("gems", component.gem_name, component.version))
      redis.del(key("gems", component.gem_name))
      redis.srem(key("gems"), component.gem_name)
      changed!
    end

    def changed!
      @stale = true
      redis.set(key("index", "changed"), Time.now.to_f.to_s)
    end

    def generated!
      @stale = false
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
      @stale || begin
        changed = redis.get(key("index", "changed")).to_f
        generated = redis.get(key("index", "generated")).to_f
        generated < changed
      end
    end

    def exists?(component)
      key = key("gems", component.gem_name)
      if component.version
        redis.sismember(key, component.version)
      else
        redis.exists(key)
      end
    end

    def versions(gem_name_or_component)
      gem_name = gem_name_or_component.respond_to?(:gem_name) ? gem_name_or_component.gem_name : gem_name_or_component
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
