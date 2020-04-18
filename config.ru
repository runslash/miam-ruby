require 'bundler/setup'
require_relative 'config/boot'
require 'rack'
require 'miam/middlewares/auth_middleware'
require 'miam/middlewares/request_parser_middleware'

app = Rack::Builder.new do
  # map '/_status', lambda
  use Miam::Middlewares::RequestParserMiddleware
  use Miam::Middlewares::AuthMiddleware
  run Miam::Application
end

run app
