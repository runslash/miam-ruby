module Miam
  module Operations
    class DescribeUserOperation < Operation
      def call(args)
        user = Miam::UserService.instance.find(
          context.fetch(:account_id), args.fetch('user_name')
        )
        raise OperationError, 'User not found' if user.nil?

        Output.new(
          user: user
        )
      end
    end
  end
end
