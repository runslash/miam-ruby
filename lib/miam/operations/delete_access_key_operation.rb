module Miam
  module Operations
    class DeleteAccessKeyOperation < Operation
      DELETE_EXPRESSION_ATTRIBUTE_NAMES = {
        '#id' => 'id'
      }.freeze

      USER_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#access_key_ids' => 'access_key_ids'
      }.freeze

      USER_UPDATE_EXPRESSION = <<-EOF
        DELETE #access_key_ids :access_key_id
      EOF

      USER_CONDITION_EXPRESSION = <<-EOF
        attribute_exists(#account_id) AND attribute_exists(#name)
      EOF

      def call(args)
        access_key = Miam::AccessKeyService.instance.find(
          args.fetch('access_key_id')
        )
        raise OperationError, 'Access key not found' if access_key.nil?

        Miam::DynamoService.instance.transact_write_items(
          transact_items: [
            {
              delete: {
                table_name: Miam::AccessKey.table_name,
                condition_expression: 'attribute_exists(#id)',
                expression_attribute_names: DELETE_EXPRESSION_ATTRIBUTE_NAMES,
                key: { id: args.fetch('access_key_id') }
              }
            },
            {
              update: {
                table_name: Miam::User.table_name,
                condition_expression: USER_CONDITION_EXPRESSION,
                expression_attribute_names: USER_EXPRESSION_ATTRIBUTE_NAMES,
                expression_attribute_values: {
                  ':access_key_id' => Set.new([access_key.id])
                },
                key: {
                  account_id: access_key.account_id,
                  name: access_key.user_name
                },
                update_expression: USER_UPDATE_EXPRESSION
              }
            }
          ]

        )

        Output.new(access_key_deleted: true)
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise OperationError.new(
          'Access key not found', reason: 'ACCESS_KEY_NOT_FOUND'
        )
      end
    end
  end
end
