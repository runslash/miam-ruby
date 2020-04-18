module Miam
  class PolicyService
    include Singleton

    def list(account_id, **kwargs)

    end

    def find(account_id, *names)
      if names.length > 1
        result = dynamo_service.batch_get_item(
          request_items: {
            Miam::Policy.table_name => {
              keys: names.map do |name|
                { account_id: account_id, name: name.to_s }
              end
            }
          }
        )
        result.items.map do |item|
          Miam::Policy.from_dynamo_record(item)
        end
      else
        result = dynamo_service.get_item(
          table_name: Miam::Policy.table_name,
          key: { account_id: account_id, name: names[0].to_s }
        )
        return if result.item.nil?

        Miam::Policy.from_dynamo_record(result.item)
      end
    end

    private

    def dynamo_service
      Miam::DynamoService.instance
    end
  end
end
