module Miam
  module Operations
    class DescribePolicyOperation < Operation
      def call(args)
        policy = Miam::PolicyService.instance.find(
          context.fetch(:account_id), args.fetch('policy_name')
        )
        raise OperationError, 'Policy not found' if policy.nil?

        Output.new(
          policy: policy
        )
      end
    end
  end
end
