module Miam
  class Role < Model
    include InlinePolicyAttachable
    self.table_name = "miam-#{Miam::Application.environment}-roles"

    attribute :account_id, :string
    attribute :name, :string
    attribute :policy_names
    attribute :group_names
    attribute :created_at, :datetime, default: -> { Time.now.utc }
    attribute :updated_at, :datetime, default: -> { Time.now.utc }

    def self.from_dynamo_record(item)
      new(
        account_id: item['account_id'],
        name: item['name'],
        policy_names: item['policy_names'],
        group_names: item['group_names'],
        inline_policies: item['inline_policies']&.transform_values do |element|
          Miam::InlinePolicy.from_dynamo_record(element)
        end,
        created_at: Time.at(item['created_at'].to_i),
        updated_at: Time.at(item['updated_at'].to_i)
      )
    end
  end
end
