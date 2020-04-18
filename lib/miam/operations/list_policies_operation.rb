module Miam
  module Operations
    class ListPoliciesOperation < Operation
      EXPRESSION_ATTRIBUTE_NAMES = {
        '#account_id' => 'account_id'
      }.freeze

      def call(args)
        query_params = {
          table_name: Miam::Policy.table_name,
          key_condition_expression: '#account_id = :account_id',
          expression_attribute_names: EXPRESSION_ATTRIBUTE_NAMES,
          expression_attribute_values: {
            ':account_id' => context.fetch(:account_id)
          },
          limit: args.fetch('limit', 20).to_i,
          scan_index_forward: args.fetch('sort_order', 'asc').to_s == 'asc'
        }
        if args.key?('exclusive_start_key')
          query_params[:exclusive_start_key] = args.fetch('exclusive_start_key')
        end
        result = dynamo_service.query(query_params)

        Output.new(
          total: result.count,
          last_evaluated_key: result.last_evaluated_key,
          policies: result.items.map do |item|
            Miam::Policy.from_dynamo_record(item)
          end
        )
      end

      private

      def dynamo_service
        Miam::DynamoService.instance
      end
    end
  end
end
