module Miam
  module Operations
    class CreatePolicyOperation < Operation
      PUT_POLICY_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
      }.freeze

      PUT_POLICY_VERSION_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name_version' => 'name_version'
      }.freeze

      def call(args)
        policy = Miam::Policy.new(
          account_id: context.fetch(:account_id),
          name: args.fetch('policy_name'),
          statements: args.fetch('policy_statements').map do |item|
            Miam::PolicyStatement.new(item.symbolize_keys)
          end
        )
        transact_items = [
          {
            put: {
              table_name: Miam::Policy.table_name,
              condition_expression: 'attribute_not_exists(#account_id) AND attribute_not_exists(#name)',
              expression_attribute_names: PUT_POLICY_EXPRESSION_ATTRIBUTE_NAMES,
              item: {
                account_id: policy.account_id,
                name: policy.name,
                version: policy.version,
                statements: policy.statements.as_json,
                created_at: policy.created_at.to_i,
                updated_at: policy.updated_at.to_i
              }
            }
          },
          {
            put: {
              table_name: Miam::PolicyVersion.table_name,
              condition_expression: 'attribute_not_exists(#account_id) AND attribute_not_exists(#name_version)',
              expression_attribute_names: \
                PUT_POLICY_VERSION_EXPRESSION_ATTRIBUTE_NAMES,
              item: {
                account_id: policy.account_id,
                name_version: policy.name_version,
                statements: policy.statements.as_json,
                created_at: policy.created_at.to_i
              }
            }
          }
        ]
        Miam::DynamoService.instance.transact_write_items(
          transact_items: transact_items
        )

        Output.new(policy: policy)
      rescue Aws::DynamoDB::Errors::TransactionCanceledException
        raise OperationError, 'Policy already exists'
      end
    end
  end
end
