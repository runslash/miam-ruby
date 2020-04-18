module Miam
  module Middlewares
    class RequestParserMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        env['miam.request'] = Rack::Request.new(env)
        env['miam.operation_name'] = env['miam.request'].params.fetch('Operation')
        env['miam.request.data'] = parse_request_body(
          env['miam.request'].body.read
        )
        @app.call(env)
      end

      private

      def parse_request_body(body)
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
