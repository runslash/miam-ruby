module Miam
  class RoleService
    include Singleton

    def find(account_id, name)
      result = dynamo_service.get_item(
        table_name: Miam::Role.table_name,
        key: { account_id: account_id, name: name }
      )
      return if result.item.nil?

      Miam::Role.from_dynamo_record(result.item)
    end

    def mfind(account_id, names)
      return if names.length == 0

      result = dynamo_service.batch_get_item(
        request_items: {
          Miam::Role.table_name => {
            keys: names.map do |name|
              { account_id: account_id, name: name.to_s }
            end
          }
        }
      )
      result.responses[Miam::Role.table_name].map do |item|
        Miam::Role.from_dynamo_record(item)
      end
    end

    private

    def dynamo_service
      Miam::DynamoService.instance
    end
  end
end
