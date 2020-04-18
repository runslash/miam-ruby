# frozen_string_literal: true

module Miam
  module Operations
    class DeleteGroupOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id', '#name' => 'name',
        '#user_names' => 'user_names', '#policy_names' => 'policy_names'
      }.freeze

      EXPRESSION_ATTRIBUTE_VALUES = { ':zero' => 0 }.freeze

      FAILURE_MESSAGE = \
        'Unable to delete group, please ensure that all ' \
        'users and policies has been removed from it before deleting'

      CONDITION_EXPRESSION = <<-EXPRESSION
        attribute_exists(#account_id) AND attribute_exists(#name) AND
        (attribute_not_exists(#user_names) OR size(#user_names) = :zero) AND
        (attribute_not_exists(#policy_names) OR size(#policy_names) = :zero)
      EXPRESSION

      def call(args)
        group = Miam::GroupService.instance.find(
          context.fetch(:account_id), args.fetch('group_name')
        )
        raise OperationError, 'Group not found' if group.nil?

        Miam::DynamoService.instance.delete_item(
          table_name: Miam::Group.table_name,
          condition_expression: CONDITION_EXPRESSION,
          expression_attribute_names: EXPRESSION_ATTRIBUTE_NAMES,
          expression_attribute_values: EXPRESSION_ATTRIBUTE_VALUES,
          key: { account_id: group.account_id, name: group.name }
        )

        Output.new(deleted: true)
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise OperationError, FAILURE_MESSAGE
      end
    end
  end
end
