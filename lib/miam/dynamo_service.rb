module Miam
  class DynamoService
    include Singleton

    def get_item(params)
      checkout { |cl| cl.get_item(params) }
    end

    def put_item(params)
      checkout { |cl| cl.put_item(params) }
    end

    def update_item(params)
      checkout { |cl| cl.update_item(params) }
    end

    def batch_get_item(params)
      checkout { |cl| cl.batch_get_item(params) }
    end

    def delete_item(params)
      checkout { |cl| cl.delete_item(params) }
    end

    def transact_write_items(params)
      checkout { |cl| cl.transact_write_items(params) }
    end

    def query(params)
      checkout { |cl| cl.query(params) }
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
  end
end
