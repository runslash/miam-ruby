module Miam
  class Configuration
    attr_accessor :concurrency, :environment, :operation_parameter_name,
                  :cache_store_adapter

    def initialize(&block)
      self.concurrency = 4
      self.environment = 'development'
      self.operation_parameter_name = 'Operation'
      self.cache_store_adapter = Miam::CacheStores::LruCacheStore.new
      instance_exec(&block) if block_given?
    end

    def to_h
      {
        concurrency: concurrency,
        environment: environment,
        operation_parameter_name: operation_parameter_name,
        cache_store_adapter: cache_store_adapter
      }
    end
  end
end
