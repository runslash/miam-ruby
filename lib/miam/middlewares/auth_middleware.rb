# frozen_string_literal: true

module Miam
  module Middlewares
    class AuthMiddleware
      OPERATION_WHITELIST = %w[Authorize].freeze
      AUTH_ERROR_RESPONSE = [
        401,
        { 'content-type' => 'application/json'},
        [{ 'error' => 'Authentication error' }]
      ].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        request = env['miam.request']
        unless OPERATION_WHITELIST.include?(env['miam.operation_name'])
          result = Miam::Operations::AuthorizeOperation.call(
            'operation_name' => env['miam.operation_name'],
            'auth_token' => request.get_header('HTTP_AUTHORIZATION').to_s,
            'auth_headers' => env['miam.request.headers'],
            'auth_body_signature' => Digest::SHA1.hexdigest(
              env['miam.request.body']
            )
          )
          return [AUTH_RESPONSE_ERROR] if result.nil?

          env['miam.account_id'] = result.account_id
          env['miam.user'] = result.user
          env['miam.auth.conditions'] = result.conditions
          env['miam.auth.resources'] = result.resources
        end

        @app.call(env)
      end
    end
  end
end
