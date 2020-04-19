module Miam
  class User < Model
    include InlinePolicyAttachable
    self.table_name = "miam-#{Miam::Application.environment}-users"

    attr_accessor :password

    attribute :account_id, :string
    attribute :name, :string
    attribute :hashed_password, :string
    attribute :password_present, :boolean, default: false
    attribute :policy_names
    attribute :group_names
    attribute :access_key_ids
    attribute :created_at, :datetime, default: -> { Time.now.utc }
    attribute :updated_at, :datetime, default: -> { Time.now.utc }

    def self.from_dynamo_record(item)
      new(
        account_id: item['account_id'],
        name: item['name'],
        password_present: !item['hashed_password'].nil?,
        policy_names: item['policy_names'],
        group_names: item['group_names'],
        access_key_ids: item['access_key_ids'],
        inline_policies: item['inline_policies']&.transform_values do |element|
          Miam::InlinePolicy.from_dynamo_record(element)
        end,
        created_at: Time.at(item['created_at'].to_i),
        updated_at: Time.at(item['updated_at'].to_i)
      )
    end

    def password=(arg)
      @password = arg.to_s
      self.hashed_password = BCrypt::Password.create(@password)
    end
  end
end
