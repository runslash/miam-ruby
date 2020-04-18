# frozen_string_literal: true

module Miam
  module Middlewares
    class AuthMiddleware
      OPERATION_WHITELIST = %w[Authorize].freeze
      AUTH_ERROR_RESPONSE = [{ 'error' => 'Authentication error' }.to_json].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        request = env['miam.request']
        unless OPERATION_WHITELIST.include?(env['miam.operation_name'])
          result = Miam::Operations::AuthorizeOperation.call(
            'operation_name' => env['miam.operation_name'],
            'authentication_string' => request.get_header('HTTP_AUTHORIZATION').to_s
          )

          env['miam.account_id'] = result.account_id
          env['miam.user'] = result.user
          env['miam.auth.conditions'] = result.conditions
          env['miam.auth.resources'] = result.resources
        end

        @app.call(env)
      rescue Miam::Operation::OperationError
        [
          401,
          { 'content-type' => 'application/json'},
          AUTH_ERROR_RESPONSE
        ]
      end
    end
  end
end
