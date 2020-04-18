module Miam
  module Operations
    class DeleteUserOperation < Operation
      def call(args)
        user = Miam::UserService.instance.find(
          context.fetch(:account_id), args.fetch('user_name')
        )
        raise OperationError, 'User not found' if user.nil?

        Miam::DynamoService.instance.delete_item(
          table_name: Miam::User.table_name,
          condition_expression: 'attribute_exists(#account_id) AND attribute_exists(#name)',
          expression_attribute_names: { '#account_id' => 'account_id', '#name' => 'name' },
          key: { account_id: user.account_id, name: user.name }
        )

        Output.new(deleted: true)
      end
    end
  end
end
