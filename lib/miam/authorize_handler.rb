module Miam
  class AuthorizeHandler
    def self.call(env)
      request_data = JSON.parse(env['rack.input'].read)
      if env['HTTP_AUTHORIZATION']
        request_data['auth_token'] = env['HTTP_AUTHORIZATION']
      end
      result = Miam::Operations::AuthorizeOperation.call(request_data)
      [200, { 'content-type' => 'application/json' }, [JSON.dump(result)]]
    rescue Miam::Operation::OperationError => e
      [
        e.message == 'FORBIDDEN' ? 403 : 400,
        { 'content-type' => 'application/json' },
        [{ 'error' => e.message }.to_json]
      ]
    rescue StandardError => e
      [
        500,
        { 'content-type' => 'application/json' },
        [{ 'error' => e.message, 'backtrace' => e.backtrace }.to_json]
      ]
    end
  end
end
