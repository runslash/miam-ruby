module Miam
  class AuthenticationHandler
    Error = Class.new(StandardError)
    AuthResult = Struct.new(
      :account_id,
      :owner_type,
      :owner_name,
      :policy_name,
      :statement
    )

    def initialize(token)
      @token = token
    end

    def allow!
      raise Error
    end
  end
end
