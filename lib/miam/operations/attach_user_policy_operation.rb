module Miam
  module Operations
    class AttachUserPolicyOperation < Operation
      UPDATE_USER_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#policy_names' => 'policy_names'
      }.freeze

      UPDATE_POLICY_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#user_names' => 'user_names'
      }.freeze

      POLICY_UPDATE_EXPRESSION = <<-EXPRESSION
        ADD #user_names :user_name_ss
      EXPRESSION

      USER_UPDATE_EXPRESSION = <<-EXPRESSION
        ADD #policy_names :policy_name_ss
      EXPRESSION

      def call(args)
        account_id = context.fetch(:account_id)
        user_name = args.fetch('user_name')
        policy_name = args.fetch('policy_name')
        transact_items = [
          {
            update: {
              table_name: Miam::Policy.table_name,
              condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name) AND NOT contains(#user_names, :user_name)',
              expression_attribute_names: \
                UPDATE_POLICY_EXPRESSION_ATTRIBUTE_NAMES,
              expression_attribute_values: {
                ':user_name_ss' => Set.new([user_name]),
                ':user_name' => user_name
              },
              key: { account_id: account_id, name: policy_name },
              update_expression: POLICY_UPDATE_EXPRESSION
            }
          },
          {
            update: {
              table_name: Miam::User.table_name,
              condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name) AND NOT contains(#policy_names, :policy_name)',
              expression_attribute_names: \
                UPDATE_USER_EXPRESSION_ATTRIBUTE_NAMES,
              expression_attribute_values: {
                ':policy_name_ss' => Set.new([policy_name]),
                ':policy_name' => policy_name
              },
              key: { account_id: account_id, name: user_name },
              update_expression: USER_UPDATE_EXPRESSION
            }
          }
        ]
        Miam::DynamoService.instance.transact_write_items(
          transact_items: transact_items
        )

        Output.new(
          user_name: user_name, policy_name: policy_name, attached: true
        )
      rescue Aws::DynamoDB::Errors::TransactionCanceledException
        raise OperationError, 'Unable to attach policy, user/policy does not exists OR policy is already attached to that user'
      end
    end
  end
end
