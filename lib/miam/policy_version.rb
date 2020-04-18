module Miam
  class PolicyVersion < Policy
    self.table_name = "miam-#{Miam::Application.environment}-policy-versions"

    def self.from_dynamo_record(item)
      name, version = item['name_version'].split('/')
      new(
        account_id: item['account_id'],
        name: name,
        version: version,
        statements: item['statements'].map do |stmt|
          Miam::PolicyStatement.from_dynamo_record(stmt)
        end,
        created_at: Time.at(item['created_at'].to_i),
        updated_at: Time.at(item['updated_at'].to_i)
      )
    end
  end
end
