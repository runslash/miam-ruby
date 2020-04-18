module Miam
  module Operations
    class CreateAccessKeyOperation < Operation
      UPDATE_EXPRESSION_ATTRIBUTE_NAMES = {
        '#id' => 'id',
        '#account_id' => 'account_id',
        '#user_name' => 'user_name',
        '#secret' => 'secret'
      }.freeze

      UPDATE_EXPRESSION = <<-EXPRESSION
        SET #account_id = :account_id, #user_name = :user_name, #secret = :secret
      EXPRESSION

      def call(args)
        access_key = Miam::AccessKey.new(
          account_id: context.fetch(:account_id),
          user_name: args.fetch('user_name')
        )
        Miam::DynamoService.instance.update_item(
          table_name: Miam::AccessKey.table_name,
          condition_expression: 'attribute_not_exists(#id)',
          expression_attribute_names: UPDATE_EXPRESSION_ATTRIBUTE_NAMES,
          expression_attribute_values: {
            ':account_id' => access_key.account_id,
            ':user_name' => access_key.user_name,
            ':secret' => access_key.secret
          },
          key: { id: access_key.id },
          update_expression: UPDATE_EXPRESSION
        )

        Output.new(
          access_key_id: access_key.id,
          secret_access_key: access_key.secret
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
