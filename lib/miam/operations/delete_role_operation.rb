module Miam
  module Operations
    class DeleteRoleOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#policy_names' => 'policy_names',
        '#group_names' => 'group_names'
      }.freeze

      CONDITION_EXPRESSION = <<-EOF
        attribute_exists(#account_id) AND attribute_exists(#name) AND
        (attribute_not_exists(#policy_names) OR size(#policy_names) = :zero) AND
        (attribute_not_exists(#group_names) OR size(#group_names) = :zero)
      EOF

      def call(args)
        role = Miam::RoleService.instance.find(
          context.fetch(:account_id), args.fetch('role_name')
        )
        raise OperationError, 'Role not found' if role.nil?

        Miam::DynamoService.instance.delete_item(
          table_name: Miam::Role.table_name,
          condition_expression: CONDITION_EXPRESSION,
          expression_attribute_names: EXPRESSION_ATTRIBUTE_NAMES,
          expression_attribute_values: { ':zero' => 0 },
          key: { account_id: role.account_id, name: role.name }
        )

        Output.new(role_name: role.name, deleted: true)
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise OperationError, \
              'Unable to delete Role, please ensure that all groups and policies has been detached before deleting it.'
      end
    end
  end
end
