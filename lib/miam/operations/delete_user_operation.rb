module Miam
  module Operations
    class DeleteUserOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#access_key_ids' => 'access_key_ids'
      }.freeze

      CONDITION_EXPRESSION = <<-EOF
        attribute_exists(#account_id) AND attribute_exists(#name) AND
        (attribute_not_exists(#access_key_ids) OR size(#access_key_ids) = :zero)
      EOF

      def call(args)
        user = Miam::UserService.instance.find(
          context.fetch(:account_id), args.fetch('user_name')
        )
        raise OperationError, 'User not found' if user.nil?

        Miam::DynamoService.instance.delete_item(
          table_name: Miam::User.table_name,
          condition_expression: CONDITION_EXPRESSION,
          expression_attribute_names: EXPRESSION_ATTRIBUTE_NAMES,
          expression_attribute_values: { ':zero' => 0 },
          key: { account_id: user.account_id, name: user.name }
        )

        Output.new(deleted: true)
      end
    end
  end
end
