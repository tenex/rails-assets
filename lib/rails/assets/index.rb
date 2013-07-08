require "redis"

module Rails
  module Assets
    class Index
      # def find(pkg)
      #   name, version = name_and_version(pkg)
      #   versions = redis.smembers(key("gems", name))
      # end

      def save(component)
        logger.debug "Storing gem #{component.name} #{component.version}"

        deps = component.gem_dependencies
        unless deps.empty?
          logger.debug "aargs: #{deps.to_a.flatten.inspect}"
          redis.hmset(key("gems", component.gem_name, component.version), *deps.to_a.flatten)
        end

        redis.sadd(key("gems", component.gem_name), component.version)
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
