module Miam
  module Operations
    class ListUserAccessKeysOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id'
      }.freeze

      def call(args)
        user = Miam::UserService.instance.find(
          context.fetch(:account_id), args.fetch('user_name')
        )
        raise OperationError, 'User not found' if user.nil?

        access_keys = \
          if !user.access_key_ids.nil? && user.access_key_ids.length > 0
            Miam::AccessKeyService.instance.mfind(*user.access_key_ids.to_a)
          end

        Output.new(access_keys: access_keys || [])
      end

      private

      def dynamo_service
        Miam::DynamoService.instance
      end
    end
  end
end
