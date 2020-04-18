require 'bundler/setup'
require 'miam'

Miam::Application.configure do
  self.concurrency = 4
end
