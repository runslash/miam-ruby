require 'bundler/setup'
require 'optparse'
require 'miam'

Miam::Application.configure do |config|
  config.concurrency = ENV.fetch('MIAM_CONCURRENCY', 4).to_i
  config.environment = ENV.fetch('MIAM_ENV', 'development').to_s
  if ENV.key?('MIAM_REDIS_URL')
    config.cache_store_adapter = Miam::CacheStores::RedisCacheStore.new(
      url: ENV.fetch('MIAM_REDIS_URL')
    )
  end
end
