module Miam
  class UserService
    include Singleton

    def find(account_id, user_name)
      result = Miam::DynamoService.instance.get_item(
        table_name: Miam::User.table_name,
        key: { account_id: account_id, name: user_name }
      )
      return if result.item.nil?

      Miam::User.from_dynamo_record(result.item)
    end
  end
end
