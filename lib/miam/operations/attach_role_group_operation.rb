module Miam
  module Operations
    class AttachRoleGroupOperation < Operation
      UPDATE_ROLE_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#group_names' => 'group_names'
      }.freeze

      UPDATE_GROUP_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#role_names' => 'role_names'
      }.freeze

      GROUP_UPDATE_EXPRESSION = <<-EXPRESSION
        ADD #role_names :role_name_ss
      EXPRESSION

      ROLE_UPDATE_EXPRESSION = <<-EXPRESSION
        ADD #group_names :group_name_ss
      EXPRESSION

      def call(args)
        account_id = context.fetch(:account_id)
        role_name = args.fetch('role_name')
        group_name = args.fetch('group_name')
        transact_items = [
          {
            update: {
              table_name: Miam::Group.table_name,
              condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name) AND NOT contains(#role_names, :role_name)',
              expression_attribute_names: \
                UPDATE_GROUP_EXPRESSION_ATTRIBUTE_NAMES,
              expression_attribute_values: {
                ':role_name_ss' => Set.new([role_name]),
                ':role_name' => role_name
              },
              key: { account_id: account_id, name: group_name },
              update_expression: GROUP_UPDATE_EXPRESSION
            }
          },
          {
            update: {
              table_name: Miam::Role.table_name,
              condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name) AND NOT contains(#group_names, :group_name)',
              expression_attribute_names: \
                UPDATE_ROLE_EXPRESSION_ATTRIBUTE_NAMES,
              expression_attribute_values: {
                ':group_name_ss' => Set.new([group_name]),
                ':group_name' => group_name
              },
              key: { account_id: account_id, name: role_name },
              update_expression: ROLE_UPDATE_EXPRESSION
            }
          }
        ]
        Miam::DynamoService.instance.transact_write_items(
          transact_items: transact_items
        )

        Output.new(
          role_name: role_name, group_name: group_name, attached: true
        )
      rescue Aws::DynamoDB::Errors::TransactionCanceledException
        raise OperationError, 'Unable to attach group, role/group does not exists OR group is already attached to that role'
      end
    end
  end
end
