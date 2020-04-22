module Miam
  module Operations
    class AttachRolePolicyOperation < Operation
      UPDATE_ROLE_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#policy_names' => 'policy_names'
      }.freeze

      UPDATE_POLICY_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#role_names' => 'role_names'
      }.freeze

      ROLE_UPDATE_EXPRESSION = <<-EXPRESSION
        ADD #policy_names :policy_name_ss
      EXPRESSION

      POLICY_UPDATE_EXPRESSION = <<-EXPRESSION
        ADD #role_names :role_name_ss
      EXPRESSION

      def call(args)
        account_id = context.fetch(:account_id)
        role_name = args.fetch('role_name')
        policy_name = args.fetch('policy_name')
        transact_items = [
          {
            update: {
              table_name: Miam::Policy.table_name,
              condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name) AND NOT contains(#role_names, :role_name)',
              expression_attribute_names: \
                UPDATE_POLICY_EXPRESSION_ATTRIBUTE_NAMES,
              expression_attribute_values: {
                ':role_name_ss' => Set.new([role_name]),
                ':role_name' => role_name
              },
              key: { account_id: account_id, name: policy_name },
              update_expression: POLICY_UPDATE_EXPRESSION
            }
          },
          {
            update: {
              table_name: Miam::Role.table_name,
              condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name) AND NOT contains(#policy_names, :policy_name)',
              expression_attribute_names: \
                UPDATE_ROLE_EXPRESSION_ATTRIBUTE_NAMES,
              expression_attribute_values: {
                ':policy_name_ss' => Set.new([policy_name]),
                ':policy_name' => policy_name
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
          role_name: role_name, policy_name: policy_name, attached: true
        )
      rescue Aws::DynamoDB::Errors::TransactionCanceledException
        raise OperationError, 'Unable to attach policy, role/policy does not exists OR policy is already attached to that role'
      end
    end
  end
end
