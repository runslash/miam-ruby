module Miam
  class AuthenticationHandler
    Error = Class.new(StandardError)

    def initialize(token)
      @token = token
    end

    def allow!
      raise Error
    end
  end
end
