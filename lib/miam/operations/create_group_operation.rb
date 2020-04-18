module Miam
  module Operations
    class CreateGroupOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name'
      }.freeze

      def call(args)
        group = Miam::Group.new(
          account_id: context.fetch(:account_id),
          name: args.fetch('group_name')
        )
        Miam::DynamoService.instance.put_item(
          table_name: Miam::Group.table_name,
          condition_expression: 'attribute_not_exists(#account_id) AND attribute_not_exists(#name)',
          expression_attribute_names: EXPRESSION_ATTRIBUTE_NAMES,
          item: {
            account_id: group.account_id,
            name: group.name
          }
        )

        Output.new(group: group)
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise OperationError.new(
          "Group '#{group.name}' already exists",
          reason: 'GROUP_NOT_UNIQUE'
        )
      end
    end
  end
end
