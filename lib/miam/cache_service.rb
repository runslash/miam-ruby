module Miam
  class CacheService
    include Singleton

    def put(key, value, ttl: 60)
      checkout do |cl|
        cl.put_item(
          table_name: table_name,
          condition_expression: 'attribute_not_exists(#e) OR #e < :n',
          expression_attribute_names: { '#e' => 'e' },
          expression_attribute_values: { ':n' => Time.now.to_i },
          item: { k: key.to_s, v: JSON.dump(value), e: Time.now.to_i + ttl }
        )
      end
      true
    rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
      false
    end

    def get(key, default_value = nil)
      result = checkout do |cl|
        cl.get_item(table_name: table_name, key: { k: key.to_s })
      end
      return default_value if result.item.nil?

      return default_value unless result.item['e'].to_i > Time.now.to_i

      JSON.parse(result.item['v'])
    rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
      default_value
    end

    def checkout(&_block)
      conn = nil
      conn = @connection_pool.pop
      yield(conn)
    ensure
      @connection_pool << conn unless conn.nil?
    end

    protected

    def initialize
      @connection_pool = Queue.new.tap do |queue|
        Miam::Application.configuration.concurrency.times do
          queue << Aws::DynamoDB::Client.new
        end
      end
    end

    def table_name
      "miam-#{Miam::Application.environment}-cache"
    end
  end
end
