module Miam
  module Operations
    class DeleteAccessKeyOperation < Operation
      DELETE_EXPRESSION_ATTRIBUTE_NAMES = {
        '#id' => 'id'
      }.freeze

      def call(args)
        Miam::DynamoService.instance.delete_item(
          table_name: Miam::AccessKey.table_name,
          condition_expression: 'attribute_exists(#id)',
          expression_attribute_names: DELETE_EXPRESSION_ATTRIBUTE_NAMES,
          key: { id: args.fetch('access_key_id') }
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
