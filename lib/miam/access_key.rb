module Miam
  class AccessKey < Model
    self.table_name = "miam-#{Miam::Application.environment}-access-keys"

    attribute :id, :string, default: -> { 'AK' + Miam::Utils::Base32.random(12) }
    attribute :account_id, :string
    attribute :user_name, :string

    def self.random_secret
      SecureRandom.base64(32).slice(0, 43)
    end

    def self.from_dynamo_record(item)
      new(
        id: item['id'],
        account_id: item['account_id'],
        user_name: item['user_name']
      )
    end
  end
end
