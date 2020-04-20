module Miam
  module CacheStores
    class RedisCacheStore
      def initialize(*args)
        @connection_pool = Queue.new.tap do |queue|
          Miam::Application.configuration.concurrency.times do
            queue << Redis.new(*args)
          end
        end
      end

      def set(key, value, ttl = 60)
        checkout { |cl| cl.set(key.to_s, value.to_s, ex: ttl.to_i) }
      end

      def get(key)
        checkout { |cl| cl.get(key.to_s) }
      end

      def delete(key)
        checkout { |cl| cl.del(key.to_s) }
      end

      private

      def checkout(&_block)
        conn = nil
        conn = @connection_pool.pop
        yield(conn)
      ensure
        @connection_pool << conn unless conn.nil?
      end
    end
  end
end
