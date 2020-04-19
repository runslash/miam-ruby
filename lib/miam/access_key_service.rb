module Miam
  class AccessKeyService
    include Singleton

    def list(account_id, **kwargs)
    end

    def secret_access_key_for(access_key_id)
      result = dynamo_service.get_item(
        table_name: Miam::AccessKey.table_name,
        key: { id: access_key_id }
      )
      return if result.item.nil?

      result.item.fetch('secret')
    end

    def find_with_secret(access_key_id)
      result = dynamo_service.get_item(
        table_name: Miam::AccessKey.table_name,
        key: { id: access_key_id }
      )
      return if result.item.nil?

      [Miam::AccessKey.from_dynamo_record(result.item), result.item['secret']]
    end

    def find(*access_key_ids)
      if access_key_ids.is_a?(Array) && access_key_ids.length > 1
        result = dynamo_service.batch_get_item(
          request_items: {
            Miam::AccessKey.table_name => {
              keys: access_key_ids.map do |access_key_id|
                { id: access_key_id.to_s }
              end
            }
          }
        )
        result.responses[Miam::AccessKey.table_name].map do |item|
          Miam::AccessKey.from_dynamo_record(item)
        end
      else
        result = dynamo_service.get_item(
          table_name: Miam::AccessKey.table_name,
          key: { id: access_key_ids[0].to_s }
        )
        return if result.item.nil?

        Miam::AccessKey.from_dynamo_record(result.item)
      end
    end

    private

    def dynamo_service
      Miam::DynamoService.instance
    end
  end
end
