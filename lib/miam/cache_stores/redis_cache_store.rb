module Miam
  module CacheStores
    class RedisCacheStore
      def initialize(*args)
        @redis = args[0].is_a?(Redis) ? args[0] : Redis.new(*args)
      end

      def set(key, value, ttl = 60)
        @redis.set(key.to_s, value.to_s, ex: ttl.to_i)
      end

      def get(key)
        @redis.get(key.to_s)
      end

      def delete(key)
        @redis.del(key.to_s)
      end
    end
  end
end
