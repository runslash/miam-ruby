module Miam
  module Middlewares
    class RequestParserMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        env['miam.request'] = Rack::Request.new(env)
        env['miam.operation_name'] = env['miam.request'].params.fetch('Operation')
        env['miam.request.body'] = env['miam.request'].body.read
        env['miam.request.data'] = parse_request_body(env['miam.request.body'])
        env['miam.request.headers'] = parse_headers(env)
        @app.call(env)
      end

      private

      def parse_headers(env)
        http_headers = env.select do |k,v|
          k.start_with?('HTTP_')
        end
        http_headers.each_with_object({}) do |(key, val), hash|
          hash[key.sub(/^HTTP_/, '').downcase] = val
        end
      end

      def parse_request_body(body)
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
