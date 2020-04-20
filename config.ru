require 'bundler/setup'
require_relative 'config/boot'
require 'rack'
require 'miam/middlewares/auth_middleware'
require 'miam/middlewares/request_parser_middleware'

app = Rack::Builder.new do
  map '/authorize' do
    run(
      lambda do |env|
        request_data = JSON.parse(env['rack.input'].read)
        if env['HTTP_AUTHORIZATION']
          request_data['auth_token'] = env['HTTP_AUTHORIZATION']
        end
        result = Miam::Operations::AuthorizeOperation.call(request_data)
        [200, { 'content-type' => 'application/json' }, [JSON.dump(result)]]
      end
    )
  end

  use Miam::Middlewares::RequestParserMiddleware
  use Miam::Middlewares::AuthMiddleware
  run Miam::Application
end

run app
