require 'bundler/setup'
require 'miam'

Miam::Application.configure do
  self.concurrency = 4
  self.cache_store_adapter = Miam::CacheStores::RedisCacheStore.new
end
