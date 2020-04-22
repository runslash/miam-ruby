module Miam
  module Operations
    class DescribeRoleOperation < Operation
      def call(args)
        role = Miam::RoleService.instance.find(
          context.fetch(:account_id), args.fetch('role_name')
        )
        raise OperationError, 'Role not found' if role.nil?

        Output.new(
          role: role
        )
      end
    end
  end
end
