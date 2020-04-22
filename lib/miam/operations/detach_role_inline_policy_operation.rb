module Miam
  module Operations
    class DetachRoleInlinePolicyOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#inline_policies' => 'inline_policies'
      }.freeze

      UPDATE_EXPRESSION = <<-EOF
        REMOVE #inline_policies.#policy_name
      EOF

      def call(args)
        account_id = context.fetch(:account_id)
        role_name = args.fetch('role_name')
        policy_name = args.fetch('policy_name')
        dynamo_service.update_item(
          table_name: Miam::Role.table_name,
          condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name) AND attribute_exists(#inline_policies.#policy_name)',
          expression_attribute_names: EXPRESSION_ATTRIBUTE_NAMES.merge(
            '#policy_name' => policy_name
          ),
          key: { account_id: account_id, name: role_name },
          update_expression: UPDATE_EXPRESSION
        )
        Output.new(
          role_name: role_name,
          inline_policy_name: policy_name,
          inline_policy_detached: true
        )
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise OperationError, 'Unable to detach this Inline Policy from Role'
      end

      private

      def dynamo_service
        Miam::DynamoService.instance
      end
    end
  end
end
