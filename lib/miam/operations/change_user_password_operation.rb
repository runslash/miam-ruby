module Miam
  module Operations
    class ChangeUserPasswordOperation < Operation
      UPDATE_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#hashed_password' => 'hashed_password'
      }.freeze

      UPDATE_EXPRESSION = <<-EXPRESSION
        SET #hashed_password = :hashed_password
      EXPRESSION

      def call(args)
        user = Miam::User.new(
          account_id: context.fetch(:account_id),
          name: args.fetch('user_name'),
          password: args.fetch('user_password')
        )
        raise OperationError, 'User not found' if user.nil?

        Miam::DynamoService.instance.update_item(
          table_name: Miam::User.table_name,
          condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name)',
          expression_attribute_names: UPDATE_EXPRESSION_ATTRIBUTE_NAMES,
          expression_attribute_values: {
            ':hashed_password' => user.hashed_password
          },
          key: { account_id: user.account_id, name: user.name },
          update_expression: UPDATE_EXPRESSION
        )

        Output.new(password_changed: true)
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise OperationError.new(
          "User '#{user.name}' already exists",
          reason: 'USER_NOT_UNIQUE'
        )
      end
    end
  end
end
