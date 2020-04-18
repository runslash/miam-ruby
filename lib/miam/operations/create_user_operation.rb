module Miam
  module Operations
    class CreateUserOperation < Operation
      UPDATE_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#hashed_password' => 'hashed_password',
        '#created_at' => 'created_at',
        '#updated_at' => 'updated_at'
      }.freeze

      UPDATE_EXPRESSION = <<-EXPRESSION
        SET #hashed_password = :hashed_password, #created_at = :created_at, #updated_at = :updated_at
      EXPRESSION

      def call(args)
        user = Miam::User.new(
          account_id: context.fetch(:account_id),
          name: args.fetch('user_name'),
          password: args.fetch('user_password')
        )
        Miam::DynamoService.instance.update_item(
          table_name: Miam::User.table_name,
          condition_expression: 'attribute_not_exists(#account_id) AND attribute_not_exists(#name)',
          expression_attribute_names: UPDATE_EXPRESSION_ATTRIBUTE_NAMES,
          expression_attribute_values: {
            ':hashed_password' => user.hashed_password,
            ':created_at' => user.created_at.to_i,
            ':updated_at' => user.updated_at.to_i
          },
          key: { account_id: user.account_id, name: user.name },
          update_expression: UPDATE_EXPRESSION
        )

        Output.new(
          user: user
        )
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise OperationError.new(
          "User '#{user.name}' already exists",
          reason: 'USER_NOT_UNIQUE'
        )
      end
    end
  end
end
