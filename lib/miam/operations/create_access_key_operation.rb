module Miam
  module Operations
    class CreateAccessKeyOperation < Operation
      PUT_ACCESS_KEY_EXPRESSION_ATTRIBUTE_NAMES = {
        '#id' => 'id'
      }.freeze

      UPDATE_USER_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name',
        '#access_key_ids' => 'access_key_ids'
      }.freeze

      USER_CONDITION_EXPRESSION = <<-EOF
        attribute_exists(#account_id) AND attribute_exists(#name) AND
        (attribute_not_exists(#access_key_ids) OR size(#access_key_ids) < :max_access_keys)
      EOF

      USER_UPDATE_EXPRESSION = <<-EXPRESSION
        ADD #access_key_ids :access_key_id_ss
      EXPRESSION

      ERROR_MESSAGE = \
        "Unable to create an access key for this user, possible reasons: \n" +
        "- User does not exists\n" +
        '- User has exceeded his maximum number of access keys'

      def call(args)
        access_key = Miam::AccessKey.new(
          account_id: context.fetch(:account_id),
          user_name: args.fetch('user_name')
        )
        secret_access_key = Miam::AccessKey.random_secret
        Miam::DynamoService.instance.transact_write_items(
          transact_items: [
            {
              put: {
                table_name: Miam::AccessKey.table_name,
                condition_expression: 'attribute_not_exists(#id)',
                expression_attribute_names: \
                  PUT_ACCESS_KEY_EXPRESSION_ATTRIBUTE_NAMES,
                item: {
                  id: access_key.id,
                  account_id: access_key.account_id,
                  secret: secret_access_key,
                  user_name: access_key.user_name
                }
              }
            },
            {
              update: {
                table_name: Miam::User.table_name,
                condition_expression: USER_CONDITION_EXPRESSION,
                expression_attribute_names: \
                  UPDATE_USER_EXPRESSION_ATTRIBUTE_NAMES,
                expression_attribute_values: {
                  ':access_key_id_ss' => Set.new([access_key.id]),
                  ':max_access_keys' => 2
                },
                key: {
                  account_id: access_key.account_id, name: access_key.user_name
                },
                update_expression: USER_UPDATE_EXPRESSION
              }
            }
          ]
        )

        Output.new(
          access_key_id: access_key.id,
          secret_access_key: secret_access_key,
          user_name: access_key.user_name
        )
      rescue Aws::DynamoDB::Errors::TransactionCanceledException
        raise OperationError, ERROR_MESSAGE
      end
    end
  end
end
