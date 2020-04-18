module Miam
  module Operations
    class UpdatePolicyOperation < Operation
      UPDATE_POLICY_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#version' => 'version',
        '#statements' => 'statements',
        '#updated_at' => 'updated_at'
      }.freeze

      PUT_POLICY_VERSION_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name_version' => 'name_version'
      }.freeze

      POLICY_UPDATE_EXPRESSION = <<-EXPRESSION
        SET #version = :version, #statements = :statements,
            #updated_at = :updated_at
      EXPRESSION

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
            update: {
              table_name: Miam::Policy.table_name,
              condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name)',
              expression_attribute_names: \
                UPDATE_POLICY_EXPRESSION_ATTRIBUTE_NAMES,
              expression_attribute_values: {
                ':version' => policy.version,
                ':statements' => policy.statements.as_json,
                ':updated_at' => policy.updated_at.to_i
              },
              key: { account_id: policy.account_id, name: policy.name },
              update_expression: POLICY_UPDATE_EXPRESSION
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
        result = Miam::DynamoService.instance.transact_write_items(
          transact_items: transact_items
        )

        Output.new(
          policy: Miam::PolicyService.instance.find(
            policy.account_id, policy.name
          )
        )
      rescue Aws::DynamoDB::Errors::TransactionCanceledException
        raise OperationError, 'Policy already exists'
      end
    end
  end
end
