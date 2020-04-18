module Miam
  module Operations
    class AuthorizeOperation < Operation
      AUTH_MECHANISMS = {
        'MIAM-AK-V1' => :MiamAccessKeyV1
      }.freeze

      def call(args)
        operation_name = args.fetch('operation_name')
        auth_handler = parse_authorization_string(
          args.fetch('authentication_string')
        )
        policy, policy_statement = auth_handler.allow!(
          operation_name,
          conditions: args.fetch('auth_conditions', nil)
        )
        if policy.nil? || policy_statement.nil?
          # raise OperationError, 'Authentication error'
        end

        Output.new(
          account_id: '1000',
          user: Miam::User.new,
          resource: policy_statement&.resource,
          condition: policy_statement&.condition
        )
      end

      private

      def parse_authorization_string(str)
        matches = str.match(/\A([^ ]+) (.+)\z/i)
        raise OperationError, 'Authentication token invalid' if matches.nil?

        handler_klass_name = AUTH_MECHANISMS.fetch(matches[1], nil)
        if handler_klass_name.nil?
          raise OperationError, 'Authentication handler not found'
        end

        Miam::AuthenticationHandlers.const_get(handler_klass_name).new(
          matches[2]
        )
      end
    end
  end
end
