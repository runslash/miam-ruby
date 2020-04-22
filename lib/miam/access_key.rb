module Miam
  class AccessKey < Model
    self.table_name = "miam-#{Miam::Application.environment}-access-keys"

    attribute :id, :string, default: -> { 'AK' + Miam::Utils::Base32.random(12) }
    attribute :account_id, :string
    attribute :role_name, :string, default: nil
    attribute :user_name, :string, default: nil
    attribute :expires_at, :datetime, default: nil

    def self.random_secret
      SecureRandom.base64(32).slice(0, 43)
    end

    def self.from_dynamo_record(item)
      new(
        id: item['id'],
        account_id: item['account_id'],
        user_name: item['user_name'],
        role_name: item['role_name'],
        expires_at: \
          (Time.at(item['expires_at'].to_i) unless item['expires_at'].nil?)
      )
    end

    def expired?
      return false if expires_at.nil?

      expires_at <= Time.now
    end

    def owner_type
      !user_name.nil? ? 'user' : 'role'
    end

    def owner_name
      !user_name.nil? ? user_name : role_name
    end
  end
end
