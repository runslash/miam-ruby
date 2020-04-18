require 'singleton'
require 'json'
require 'ostruct'
require 'time'
require 'aws-sdk-dynamodb'
require 'active_model'
require 'bcrypt'
require 'miam/version'
require 'miam/application'
require 'miam/operation'
require 'miam/dynamo_service'
require 'miam/user_service'
require 'miam/policy_service'
require 'miam/configuration'
require 'miam/model'
require 'miam/user'
require 'miam/access_key'
require 'miam/policy'
require 'miam/policy_statement'
require 'miam/policy_version'
require 'miam/utils/base32'

# authentication handlers
require 'miam/authentication_handler'
require 'miam/authentication_handlers/miam_access_key_v1.rb'

# operations
require 'miam/operations/authorize_operation'
require 'miam/operations/describe_user_operation'
require 'miam/operations/create_user_operation'
require 'miam/operations/delete_user_operation'
require 'miam/operations/change_user_password_operation'
require 'miam/operations/create_access_key_operation'
require 'miam/operations/delete_access_key_operation'
require 'miam/operations/create_policy_operation'
require 'miam/operations/describe_policy_operation'
require 'miam/operations/update_policy_operation'
require 'miam/operations/attach_user_policy_operation'
require 'miam/operations/detach_user_policy_operation'

module Miam
  class Error < StandardError; end
end
