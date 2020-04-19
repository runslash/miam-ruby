module Miam
  class GroupService
    include Singleton

    def list(account_id, **kwargs)

    end

    def find(account_id, name)
      result = dynamo_service.get_item(
        table_name: Miam::Group.table_name,
        key: { account_id: account_id, name: name }
      )
      return if result.item.nil?

      Miam::Group.from_dynamo_record(result.item)
    end

    def mfind(account_id, names)
      return [] if names.length == 0

      result = dynamo_service.batch_get_item(
        request_items: {
          Miam::Group.table_name => {
            keys: names.map do |name|
              { account_id: account_id, name: name.to_s }
            end
          }
        }
      )
      result.responses[Miam::Group.table_name].map do |item|
        Miam::Group.from_dynamo_record(item)
      end
    end

    private

    def dynamo_service
      Miam::DynamoService.instance
    end
  end
end
