module Miam
  class Group < Model
    include InlinePolicyAttachable

    self.table_name = "miam-#{Miam::Application.environment}-groups"

    attribute :account_id, :string
    attribute :name, :string
    attribute :user_names
    attribute :role_names
    attribute :policy_names
    attribute :created_at, :datetime, default: -> { Time.now.utc }
    attribute :updated_at, :datetime, default: -> { Time.now.utc }

    validates :account_id, :name, presence: true

    def self.from_dynamo_record(item)
      new(
        account_id: item['account_id'],
        name: item['name'],
        user_names: item['user_names'],
        role_names: item['role_names'],
        policy_names: item['policy_names'],
        inline_policies: item['inline_policies']&.transform_values do |element|
          Miam::InlinePolicy.from_dynamo_record(element)
        end,
        created_at: Time.at(item['created_at'].to_i),
        updated_at: Time.at(item['updated_at'].to_i)
      )
    end
  end
end
