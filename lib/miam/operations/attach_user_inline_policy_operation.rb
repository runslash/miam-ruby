module Miam
  module Operations
    class AttachUserInlinePolicyOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#inline_policies' => 'inline_policies'
      }.freeze

      UPDATE_EXPRESSION = <<-EOF
        SET #inline_policies.#policy_name = :policy_document
      EOF

      def call(args)
        account_id = context.fetch(:account_id)
        user_name = args.fetch('user_name')
        policy_name = args.fetch('policy_name')
        policy_statements = args.fetch('policy_statements').map do |item|
          Miam::PolicyStatement.new(item.symbolize_keys)
        end
        policy = Miam::InlinePolicy.new(
          name: policy_name,
          statements: policy_statements
        )
        dynamo_service.update_item(
          table_name: Miam::User.table_name,
          condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name)',
          expression_attribute_names: EXPRESSION_ATTRIBUTE_NAMES.merge(
            '#policy_name' => policy.name
          ),
          expression_attribute_values: {
            ':policy_document' => {
              'name' => policy.name,
              'statements' => policy.statements.as_json,
              'updated_at' => Time.now.to_i
            }
          },
          key: { account_id: account_id, name: user_name },
          update_expression: UPDATE_EXPRESSION
        )
        Output.new(
          user_name: user_name,
          inline_policy: policy
        )
      end

      private

      def dynamo_service
        Miam::DynamoService.instance
      end
    end
  end
end
