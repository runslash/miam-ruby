module Miam
  class Application
    include Singleton

    OPERATIONS = {
      # USERS
      'DescribeUser' => :DescribeUserOperation,
      'CreateUser' => :CreateUserOperation,
      'DeleteUser' => :DeleteUserOperation,
      'ChangeUserPassword' => :ChangeUserPasswordOperation,
      'ListUserPolicies' => :ListUserPoliciesOperation,
      'ListUserAccessKeys' => :ListUserAccessKeysOperation,
      'AttachUserInlinePolicy' => :AttachUserInlinePolicyOperation,
      'DetachUserInlinePolicy' => :DetachUserInlinePolicyOperation,
      # GROUPS
      'CreateGroup' => :CreateGroupOperation,
      'DeleteGroup' => :DeleteGroupOperation,
      'DescribeGroup' => :DescribeGroupOperation,
      'AttachUserGroup' => :AttachUserGroupOperation,
      'DetachUserGroup' => :DetachUserGroupOperation,
      # ACCESS KEYS
      'CreateAccessKey' => :CreateAccessKeyOperation,
      'DeleteAccessKey' => :DeleteAccessKeyOperation,
      # POLICIES
      'CreatePolicy' => :CreatePolicyOperation,
      'DescribePolicy' => :DescribePolicyOperation,
      'DeletePolicy' => :DeletePolicyOperation,
      'ListPolicies' => :ListPoliciesOperation,
      'UpdatePolicy' => :UpdatePolicyOperation,
      'AttachGroupPolicy' => :AttachGroupPolicyOperation,
      'AttachUserPolicy' => :AttachUserPolicyOperation,
      'DetachGroupPolicy' => :DetachGroupPolicyOperation,
      'DetachUserPolicy' => :DetachUserPolicyOperation
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
        account_id: env.fetch('miam.account_id', nil),
        user: env.fetch('miam.user', nil),
        env: env
      )

      output = operation_handler.call(env['miam.request.data'])
      [200, { 'content-type' => 'application/json' }, [JSON.dump(output)]]
    rescue Miam::Operation::OperationError => e
      [
        400,
        { 'content-type' => 'application/json' },
        [{ 'error' => e.message, 'data' => e.data }.to_json]
      ]
    end
  end
end
