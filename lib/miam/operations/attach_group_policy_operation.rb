module Miam
  module Operations
    class AttachGroupPolicyOperation < Operation
      UPDATE_GROUP_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#policy_names' => 'policy_names'
      }.freeze

      UPDATE_POLICY_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#group_names' => 'group_names'
      }.freeze

      POLICY_UPDATE_EXPRESSION = <<-EXPRESSION
        ADD #group_names :group_name_ss
      EXPRESSION

      GROUP_UPDATE_EXPRESSION = <<-EXPRESSION
        ADD #policy_names :policy_name_ss
      EXPRESSION

      FAILURE_MESSAGE = \
        'Unable to attach policy, group/policy does not exists OR ' \
        'policy is already attached to that group'

      def call(args)
        account_id = context.fetch(:account_id)
        group_name = args.fetch('group_name')
        policy_name = args.fetch('policy_name')
        transact_items = [
          {
            update: {
              table_name: Miam::Policy.table_name,
              condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name) AND NOT contains(#group_names, :group_name)',
              expression_attribute_names: \
                UPDATE_POLICY_EXPRESSION_ATTRIBUTE_NAMES,
              expression_attribute_values: {
                ':group_name_ss' => Set.new([group_name]),
                ':group_name' => group_name
              },
              key: { account_id: account_id, name: policy_name },
              update_expression: POLICY_UPDATE_EXPRESSION
            }
          },
          {
            update: {
              table_name: Miam::Group.table_name,
              condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name) AND NOT contains(#policy_names, :policy_name)',
              expression_attribute_names: \
                UPDATE_GROUP_EXPRESSION_ATTRIBUTE_NAMES,
              expression_attribute_values: {
                ':policy_name_ss' => Set.new([policy_name]),
                ':policy_name' => policy_name
              },
              key: { account_id: account_id, name: group_name },
              update_expression: GROUP_UPDATE_EXPRESSION
            }
          }
        ]
        Miam::DynamoService.instance.transact_write_items(
          transact_items: transact_items
        )

        Output.new(
          group_name: group_name, policy_name: policy_name, attached: true
        )
      rescue Aws::DynamoDB::Errors::TransactionCanceledException
        raise OperationError, FAILURE_MESSAGE
      end
    end
  end
end
