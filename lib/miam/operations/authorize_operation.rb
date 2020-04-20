module Miam
  module Operations
    class AuthorizeOperation < Operation
      AUTH_MECHANISMS = {
        'MIAM-AK-V1' => :MiamAccessKeyV1
      }.freeze

      def call(args)
        operation_name = args.fetch('operation_name')
        auth_handler = parse_authorization_string(
          context.dig(:env, 'miam.request.headers', 'authorization') ||
            args.fetch('auth_token')
        )
        auth_result = auth_handler.allow!(
          operation_name, args.fetch('auth_body_signature'),
          headers: args.fetch('auth_headers'),
          conditions: args.fetch('auth_conditions', nil)
        )
        raise OperationError, 'AUTH_ERROR' if auth_result.nil?
        raise OperationError, 'FORBIDDEN' if auth_result.statement.deny?

        Output.new(
          account_id: auth_result.account_id,
          user_name: auth_result.user_name,
          policy_name: auth_result.policy_name,
          statement: auth_result.statement
        )
      rescue KeyError => e
        raise OperationError, "Missing parameter '#{e.key}'"
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
