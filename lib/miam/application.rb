module Miam
  class Application
    include Singleton

    OPERATIONS = {
      'Authorize' => :AuthorizeOperation,
      # USERS
      'DescribeUser' => :DescribeUserOperation,
      'CreateUser' => :CreateUserOperation,
      'DeleteUser' => :DeleteUserOperation,
      'ChangeUserPassword' => :ChangeUserPasswordOperation,
      # ACCESS KEYS
      'CreateAccessKey' => :CreateAccessKeyOperation,
      'DeleteAccessKey' => :DeleteAccessKeyOperation,
      # POLICIES
      'CreatePolicy' => :CreatePolicyOperation,
      'UpdatePolicy' => :UpdatePolicyOperation
    }.freeze

    def self.configure(&block)
      @configuration = Miam::Configuration.new(&block)
    end

    def self.configuration
      @configuration ||= Miam::Configuration.new
    end

    def self.environment=(arg)
      @configuration.environment = arg.to_s
    end

    def self.environment
      @environment ||= ENV.fetch('MIAM_ENV', 'development')
    end

    def self.call(env)
      instance.call(env)
    end

    def call(env)
      request = env['miam.request']
      operation_klass_name = OPERATIONS.fetch(
        request.params.fetch(self.class.configuration.operation_parameter_name)
      )
      operation_handler = Miam::Operations.const_get(operation_klass_name).new(
        account_id: env.fetch('miam.account_id'),
        user: env.fetch('miam.user')
      )

      output = operation_handler.call(env['miam.request.data'])
      [200, { 'content-type' => 'application/json' }, [output.to_json]]
    rescue Miam::Operation::OperationError => e
      [
        400,
        { 'content-type' => 'application/json' },
        [{ 'error' => e.message, 'data' => e.data }.to_json]
      ]
    end
  end
end
