module Miam
  module Operations
    class CreateTemporaryAccessKeyOperation < Operation
      PUT_ACCESS_KEY_EXPRESSION_ATTRIBUTE_NAMES = {
        '#id' => 'id'
      }.freeze

      ROLE_EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id',
        '#name' => 'name'
      }.freeze
      ROLE_CONDITION_EXPRESSION = <<-EOF
        attribute_exists(#account_id) AND attribute_exists(#name)
      EOF

      ERROR_MESSAGE = \
        "Unable to create a temporary access key for this role, possible reasons: \n" +
        '- Role does not exists'

      def call(args)
        ttl = args.fetch('access_key_ttl', 3600).to_i
        unless ttl > 10
          raise OperationError, \
                'Access key time-to-live is too short (must be >10)'
        end

        access_key = Miam::AccessKey.new(
          account_id: context.fetch(:account_id),
          role_name: args.fetch('role_name'),
          expires_at: Time.now + ttl
        )
        secret_access_key = Miam::AccessKey.random_secret
        Miam::DynamoService.instance.transact_write_items(
          transact_items: [
            {
              condition_check: {
                table_name: Miam::Role.table_name,
                expression_attribute_names: ROLE_EXPRESSION_ATTRIBUTE_NAMES,
                condition_expression: ROLE_CONDITION_EXPRESSION,
                key: {
                  account_id: access_key.account_id, name: access_key.role_name
                }
              }
            },
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
                  role_name: access_key.role_name,
                  expires_at: access_key.expires_at.to_i
                }
              }
            }
          ]
        )

        Output.new(
          access_key_id: access_key.id,
          secret_access_key: secret_access_key,
          role_name: access_key.role_name,
          expires_at: access_key.expires_at
        )
      rescue Aws::DynamoDB::Errors::TransactionCanceledException
        raise OperationError, ERROR_MESSAGE
      end
    end
  end
end
