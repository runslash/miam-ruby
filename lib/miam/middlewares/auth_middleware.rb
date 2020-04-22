# frozen_string_literal: true

module Miam
  module Middlewares
    class AuthMiddleware
      AuthenticationError = Class.new(Error)
      ForbiddenError = Class.new(Error)

      OPERATION_WHITELIST = %w[Authorize].freeze
      AUTH_ERROR_RESPONSE = [
        401,
        { 'content-type' => 'application/json'},
        ['{"error":"Authentication error"}']
      ].freeze

      FORBIDDEN_RESPONSE = [
        403,
        { 'content-type' => 'application/json'},
        ['{"error":"Forbidden"}']
      ].freeze


      def initialize(app)
        @app = app
      end

      def call(env)
        result = authorize!(
          env['miam.operation_name'],
          env['HTTP_AUTHORIZATION'].to_s,
          env['miam.request.headers'],
          env['miam.request.body']
        )

        env['miam.account_id'] = result.account_id
        env['miam.user'] = result.user
        env['miam.auth.conditions'] = result.conditions
        env['miam.auth.resources'] = result.resources

        @app.call(env)
      rescue AuthenticationError
        AUTH_ERROR_RESPONSE
      rescue ForbiddenError
        FORBIDDEN_RESPONSE
      end

      private

      def authorize!(operation_name, authorization, request_headers, body)
        Miam::Operations::AuthorizeOperation.call(
          'operation_name' => "iam:#{operation_name}",
          'auth_token' => authorization,
          'auth_headers' => request_headers,
          'auth_body_signature' => Digest::SHA1.hexdigest(body)
        )
      rescue Miam::Operation::OperationError => e
        raise ForbiddenError if e.message == 'FORBIDDEN'

        raise AuthenticationError
      end
    end
  end
end
