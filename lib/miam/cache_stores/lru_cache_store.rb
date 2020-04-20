module Miam
  module CacheStores
    # @author {https://github.com/ssimeonov Simeon Simeonov}, {http://swoop.com Swoop, Inc.}
    class LruCacheStore
      class Entry
        attr_reader :value
        attr_reader :expires_at

        def initialize(value, expires_at)
          @value = value
          @expires_at = expires_at
        end
      end

      def initialize(max_size = 4000, ttl = 60, expire_interval = 100)
        @max_size = max_size
        @ttl = ttl.to_f
        @expire_interval = expire_interval
        @op_count = 0
        @data = {}
        @expires_at = {}
      end

      def fetch(key, ttl: 60)
        value = get(key)
        if !value.nil?
          value
        else
          set(key, yield, ttl)
        end
      end

      # Removes a value from the cache.
      #
      # @param key [Object] the key to remove at
      # @return [Object, nil] the value at the key, when present, or `nil`
      def delete(key)
        entry = @data.delete(key)
        if entry
          @expires_at.delete(entry)
          entry.value
        else
          nil
        end
      end

      # Checks whether the cache is empty.
      #
      # @note calls to {#empty?} do not count against `expire_interval`.
      #
      # @return [Boolean]
      def empty?
        count == 0
      end

      # Clears the cache.
      #
      # @return [self]
      def clear
        @data.clear
        @expires_at.clear
        self
      end

      # Returns the number of elements in the cache.
      #
      # @note calls to {#empty?} do not count against `expire_interval`.
      #       Therefore, the number of elements is that prior to any expiration.
      #
      # @return [Integer] number of elements in the cache.
      def count
        @data.count
      end

      alias_method :size, :count
      alias_method :length, :count

      # Allows iteration over the items in the cache.
      #
      # Enumeration is stable: it is not affected by changes to the cache,
      # including value expiration. Expired values are removed first.
      #
      # @note The returned values could have expired by the time the client
      #       code gets to accessing them.
      # @note Because of its stability, this operation is very expensive.
      #       Use with caution.
      #
      # @return [Enumerator, Array<key, value>] an Enumerator, when a block is
      #     not provided, or an array of key/value pairs.
      # @yield [Array<key, value>] key/value pairs, when a block is provided.
      def each(&block)
        expire!
        @data.map { |key, entry| [key, entry.value] }.each(&block)
      end

      # Removes expired values from the cache.
      #
      # @return [self]
      def expire!
        check_expired(Time.now.to_f)
        self
      end

      # Returns information about the number of objects in the cache, its
      # maximum size and TTL.
      #
      # @return [String]
      def inspect
        "<#{self.class.name} count=#{count} max_size=#{@max_size} ttl=#{@ttl}>"
      end

      def get(key)
        t = Time.now.to_f
        check_expired(t)
        found = true
        entry = @data.delete(key) { found = false }
        if found
          if entry.expires_at <= t
            @expires_at.delete(entry)
            return nil
          else
            @data[key] = entry
            return entry.value
          end
        else
          return nil
        end
      end

      def set(key, val, ttl)
        expires_at = Time.now.to_f + ttl.to_i
        entry = Entry.new(val.to_s, expires_at)
        store_entry(key, entry)
        val
      end

      private

      def store_entry(key, entry)
        @data.delete(key)
        @data[key] = entry
        @expires_at[entry] = key
        shrink_if_needed
      end

      def shrink_if_needed
        if @data.length > @max_size
          entry = delete(@data.shift)
          @expires_at.delete(entry)
        end
      end

      def check_expired(t)
        if (@op_count += 1) % @expire_interval == 0
          while (key_value_pair = @expires_at.first) &&
                (entry = key_value_pair.first).expires_at <= t
            key = @expires_at.delete(entry)
            @data.delete(key)
          end
        end
      end
    end
  end
end
