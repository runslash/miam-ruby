# frozen_string_literal: true

module Miam
  module Operations
    class DeletePolicyOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id', '#name' => 'name',
        '#group_names' => 'group_names', '#user_names' => 'user_names'
      }.freeze

      EXPRESSION_ATTRIBUTE_VALUES = { ':zero' => 0 }.freeze

      FAILURE_MESSAGE = \
        'Unable to delete group, please ensure that all ' \
        'users and policies has been removed from it before deleting'

      CONDITION_EXPRESSION = <<-EXPRESSION
        attribute_exists(#account_id) AND attribute_exists(#name) AND
        (attribute_not_exists(#group_names) OR size(#group_names) = :zero) AND
        (attribute_not_exists(#user_names) OR size(#user_names) = :zero)
      EXPRESSION

      def call(args)
        policy = Miam::PolicyService.instance.find(
          context.fetch(:account_id), args.fetch('policy_name')
        )
        raise OperationError, 'Policy not found' if policy.nil?

        Miam::DynamoService.instance.delete_item(
          table_name: Miam::Policy.table_name,
          condition_expression: CONDITION_EXPRESSION,
          expression_attribute_names: EXPRESSION_ATTRIBUTE_NAMES,
          expression_attribute_values: EXPRESSION_ATTRIBUTE_VALUES,
          key: { account_id: policy.account_id, name: policy.name }
        )

        Output.new(deleted: true)
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise OperationError, FAILURE_MESSAGE
      end
    end
  end
end
