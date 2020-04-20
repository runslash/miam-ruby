module Miam
  class CacheStore
    attr_accessor :adapter

    def self.instance
      @instance ||= new(adapter)
    end

    def self.adapter
      @adapter ||= Miam::Application.configuration.cache_store_adapter
    end

    def self.adapter=(arg)
      @instance = nil
      @adapter = arg
    end

    def self.put(*args)
      instance.put(*args)
    end

    def self.get(*args)
      instance.get(*args)
    end

    def put(key, value, ttl: 60)
      @adapter.set(key, JSON.dump(value), ttl)
    end

    def get(key, default_value = nil)
      value = @adapter.get(key)
      return default_value if value.nil?

      JSON.parse(value)
    end

    protected

    def initialize(adapter)
      @adapter = adapter
    end
  end
end
