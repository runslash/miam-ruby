module Miam
  module Operations
    class CreateRoleOperation < Operation
      UPDATE_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name'
      }.freeze

      def call(args)
        role = Miam::Role.new(
          account_id: context.fetch(:account_id),
          name: args.fetch('role_name')
        )
        Miam::DynamoService.instance.put_item(
          table_name: Miam::Role.table_name,
          condition_expression: 'attribute_not_exists(#account_id) AND attribute_not_exists(#name)',
          expression_attribute_names: UPDATE_EXPRESSION_ATTRIBUTE_NAMES,
          item: {
            account_id: role.account_id,
            name: role.name,
            inline_policies: {},
            created_at: role.created_at.to_i,
            updated_at: role.updated_at.to_i
          }
        )

        Output.new(
          role: role
        )
      rescue KeyError => e
        raise OperationError, "Missing required parameter '#{e.key}'"
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise OperationError.new(
          "Role '#{role.name}' already exists",
          reason: 'ROLE_NOT_UNIQUE'
        )
      end
    end
  end
end
