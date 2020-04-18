module Miam
  module AuthenticationHandlers
    class MiamAccessKeyV1 < Miam::AuthenticationHandler
      def initialize(token)
        @token = token
      end

      def allow!(operation_name, **kwargs)
        p operation_name
        true
      end
    end
  end
end
