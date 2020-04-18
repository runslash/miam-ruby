module Miam
  module Operations
    class ListUserPoliciesOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id'
      }.freeze

      def call(args)
        user = Miam::UserService.instance.find(
          context.fetch(:account_id), args.fetch('user_name')
        )
        raise OperationError, 'User not found' if user.nil?

        policies = \
          if !user.policy_names.nil? && user.policy_names.length > 0
            Miam::PolicyService.instance.find(
              context.fetch(:account_id), *user.policy_names
            )
          end

        Output.new(
          policies: policies
        )
      end

      private

      def dynamo_service
        Miam::DynamoService.instance
      end
    end
  end
end
