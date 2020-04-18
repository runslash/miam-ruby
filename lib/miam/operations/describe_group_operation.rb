module Miam
  module Operations
    class DescribeGroupOperation < Operation
      def call(args)
        group = Miam::GroupService.instance.find(
          context.fetch(:account_id), args.fetch('group_name')
        )
        raise OperationError, 'Group not found' if group.nil?

        Output.new(
          group: group
        )
      end
    end
  end
end
