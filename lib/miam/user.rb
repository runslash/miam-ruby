module Miam
  class User < Model
    self.table_name = "miam-#{Miam::Application.environment}-users"

    attr_accessor :password

    attribute :account_id, :string
    attribute :name, :string
    attribute :hashed_password, :string
    attribute :policy_names
    attribute :created_at, :datetime, default: -> { Time.now.utc }
    attribute :updated_at, :datetime, default: -> { Time.now.utc }

    def self.from_dynamo_record(item)
      new(
        account_id: item['account_id'],
        name: item['name'],
        hashed_password: item['hashed_password'],
        policy_names: item['policy_names'],
        created_at: Time.at(item['created_at'].to_i),
        updated_at: Time.at(item['updated_at'].to_i)
      )
    end

    def password=(arg)
      @password = arg.to_s
      self.hashed_password = BCrypt::Password.create(@password)
    end

    def as_output
      super.except('hashed_password')
    end
  end
end
