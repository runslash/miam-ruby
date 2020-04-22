module Miam
  module Operations
    class ListRolePoliciesOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id'
      }.freeze

      def call(args)
        role = Miam::RoleService.instance.find(
          context.fetch(:account_id), args.fetch('role_name')
        )
        raise OperationError, 'Role not found' if role.nil?

        policies = \
          if !role.policy_names.nil? && role.policy_names.length > 0
            Miam::PolicyService.instance.mfind(
              context.fetch(:account_id), role.policy_names
            )
          end

        Output.new(
          policies: policies || [],
          inline_policies: role.inline_policies.values
        )
      end

      private

      def dynamo_service
        Miam::DynamoService.instance
      end
    end
  end
end
